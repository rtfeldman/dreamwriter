Editor    = require "./Editor.coffee"
DreamSync = require "./DreamSync.coffee"
DocImport = require "./DocImport.coffee"
saveAs    = require "FileSaver.js"

app = Elm.fullscreen Elm.App, {
  loadAsCurrentDoc: ["", {title: "", chapters: []}]
  listDocs: []
}

# This will be initialized once a connection to the db has been established.
sync = null

# This will be initialized once the iframe has been added to the DOM.
maybeEditor = null

withEditor = (callback) ->
  if maybeEditor?
    callback maybeEditor
  else
    # If the editor isn't initialized yet, yield and try again until it's ready.
    setTimeout (-> withEditor callback), 0

# Looks up the doc and snapshot associated with the given docId,
# writes the snapshot to the editor, and tells Elm about the new currentDocId
loadDocId = (docId) ->
  sync.getDoc(docId).then (doc) ->
    sync.getSnapshot(doc.snapshotId).then (snapshot) ->
      withEditor (editor) ->
        editor.writeHtml snapshot.html, true
        loadDoc doc.id, doc

loadDoc = (docId, doc) -> app.ports.loadAsCurrentDoc.send [docId, doc]

saveHtmlAndLoadDoc = (html) ->
  inferredDoc = DocImport.docFromHtml html

  sync.saveDocWithSnapshot(inferredDoc, {html}).then ({doc}) ->
    loadAsCurrentDoc doc.id, doc

setUpEditor = (iframe) ->
  mutationObserverOptions =
    { subtree: true, childList: true, attributes: true, characterData: true }

  maybeEditor = new Editor iframe, mutationObserverOptions, (mutations, node) ->
    sync.getCurrentDocId().then (currentDocId) ->
      sync.getDoc(currentDocId).then (doc) ->
        doc.title    = DocImport.inferTitleFrom(node) ? doc.title ? ""
        doc.chapters = DocImport.inferChaptersFrom(node)

        sync.saveDocWithSnapshot(doc, {html: node.innerHTML}).then (result) ->
          loadAsCurrentDoc result.doc.id, result.doc

##### iframe appearance hack #####

# We need to set up the iframe as soon as it appears, but we don't have a way
# to detect when that will happen, so we use a mutation observer to watch
# for it and set it up as soon as it appears.

((document, setUpEditor) ->
  iframeAppearanceObserver = new MutationObserver (mutations) ->
    iframe = document.getElementById "editor-frame"

    if iframe
      setUpEditor iframe

      # We've done what we set out to do, so we can safely disconncet now.
      iframeAppearanceObserver.disconnect()

  iframeAppearanceObserver.observe document.body, {attributes: true, childList: true}
)(document, setUpEditor)

##################################

refreshDocList = -> sync.listDocs().then app.ports.listDocs.send

app.ports.setCurrentDocId.subscribe (newDocId) ->
  if newDocId?
    # TODO Ideally this would not be Race Condition City...
    sync.getCurrentDocId().then (currentDocId) ->
      if currentDocId != newDocId
        sync.saveCurrentDocId(newDocId).then ->
          loadDocId newDocId

app.ports.newDoc.subscribe ->
  saveHtmlAndLoadDoc DocImport.blankDocHtml
  refreshDocList()

app.ports.downloadDoc.subscribe ({filename, contentType}) ->
  withEditor (editor) ->
    saveAs new Blob([editor.getHtml()], {type: contentType}), filename

DreamSync.connect().then (instance) ->
  sync = instance

  # Initialize the app based on the stored currentDocId
  sync.getCurrentDocId().then (id) ->
    if id?
      loadDocId id
    else
      saveHtmlAndLoadDoc DocImport.introDocHtml

  refreshDocList()