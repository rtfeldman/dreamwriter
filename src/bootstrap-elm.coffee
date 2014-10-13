Editor = require "./Editor.coffee"
DreamSync = require "./DreamSync.coffee"

app = Elm.fullscreen Elm.App, {
  editDoc: null
  loadDoc: ["", null]
}

sync = new DreamSync()

# This will be initialized once the iframe is added to the DOM.
editor = null

withEditor = (callback) ->
  if editor?
    callback editor
  else
    # If the editor isn't initialized yet, yield and try again until it's ready.
    setTimeout (-> withEditor callback), 0

# Looks up the doc and snapshot associated with the given docId,
# writes the snapshot to the editor, and tells Elm about the new currentDocId
loadDocId = (docId) ->
  sync.getDoc docId, (doc) ->
    sync.getSnapshot doc.snapshotId, (snapshot) ->
      withEditor (editor) ->
        editor.writeHtml snapshot.html
        app.ports.loadDoc.send [docId, doc]

inferTitleFrom = (node) ->
  node.querySelector("h1")?.textContent

inferChaptersFrom = (node) ->
  for heading in node.querySelectorAll("h2")
    {heading: heading.textContent}

# The options used to configure the mutation observer that watches the iframe.
mutationObserverOptions = {
  subtree:       true
  childList:     true
  attributes:    true
  characterData: true
}

setUpEditor = (iframe) ->
  editor = new Editor iframe, mutationObserverOptions, (mutations, node) ->
    sync.getCurrentDocId (currentDocId) ->
      sync.getDoc currentDocId, (doc) ->
        doc.title    = inferTitleFrom(node) ? doc.title ? ""
        doc.chapters = inferChaptersFrom(node)

        # Persist the update
        sync.saveDocWithSnapshot doc, {html: node.innerHTML}, (updatedDoc) ->
          app.ports.editDoc.send updatedDoc

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

app.ports.setPendingHtml.subscribe (html) ->
  if html?
    wrapperNode = document.createElement "div"
    wrapperNode.innerHTML = html

    doc = Editor.docFromNode wrapperNode

    sync.saveDocWithSnapshot doc, {html}, (doc, snapshot) ->
      app.ports.loadDoc.send [doc.id, doc]

# Initialize the app based on the stored currentDocId
sync.getCurrentDocId (id) ->
  if id?
    loadDocId id
  else
    # Passing an id with a null doc triggers loading the intro doc.
    app.ports.loadDoc.send [DreamSync.getRandomSha(), null]