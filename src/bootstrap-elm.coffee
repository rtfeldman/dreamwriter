Editor = require "./Editor.coffee"
DreamSync = require "./DreamSync.coffee"
DocImport = require "./DocImport.coffee"
saveAs    = require "FileSaver.js"

app = Elm.fullscreen Elm.App, {
  loadDoc: ["", {title: "", chapters: []}]
}

sync = new DreamSync()

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
  sync.getDoc docId, (doc) ->
    sync.getSnapshot doc.snapshotId, (snapshot) ->
      withEditor (editor) ->
        editor.writeHtml snapshot.html, true
        loadDoc doc.id, doc

loadDoc = (docId, doc) -> app.ports.loadDoc.send [docId, doc]

saveHtmlAndLoadDoc = (html) ->
  inferredDoc = DocImport.docFromHtml html

  sync.saveDocWithSnapshot inferredDoc, {html}, (doc, snapshot) ->
    loadDoc doc.id, doc

# The options used to configure the mutation observer that watches the iframe.
mutationObserverOptions = {
  subtree:       true
  childList:     true
  attributes:    true
  characterData: true
}

setUpEditor = (iframe) ->
  maybeEditor = new Editor iframe, mutationObserverOptions, (mutations, node) ->
    sync.getCurrentDocId (currentDocId) ->
      sync.getDoc currentDocId, (doc) ->
        doc.title    = DocImport.inferTitleFrom(node) ? doc.title ? ""
        doc.chapters = DocImport.inferChaptersFrom(node)

        # Persist the update
        sync.saveDocWithSnapshot doc, {html: node.innerHTML}, (updatedDoc) ->
          loadDoc updatedDoc.id, updatedDoc

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

app.ports.setCurrentDocId.subscribe (newDocId) ->
  if newDocId?
    # TODO Ideally this would not be Race Condition City...
    sync.getCurrentDocId (currentDocId) ->
      if currentDocId != newDocId
        sync.saveCurrentDocId newDocId, ->
          loadDocId newDocId

app.ports.newDoc.subscribe ->
  saveHtmlAndLoadDoc DocImport.blankDocHtml

app.ports.downloadDoc.subscribe ({filename, contentType}) ->
  withEditor (editor) ->
    saveAs new Blob([editor.getHtml()], {type: contentType}), filename

# Initialize the app based on the stored currentDocId
sync.getCurrentDocId (id) ->
  if id?
    loadDocId id
  else
    saveHtmlAndLoadDoc DocImport.introDocHtml
