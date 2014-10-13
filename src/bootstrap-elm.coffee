DocEditor = require "./DocEditor.coffee"
DreamSync = require "./DreamSync.coffee"

app = Elm.fullscreen Elm.App, {
  editDoc: null
  loadDoc: ["", null]
}

# This will be initialized once the iframe is added to the DOM.
editor = null

##### update editor #####

app.ports.setCurrentDoc.subscribe (currentDoc) ->
  withEditor (editor) ->
    editor.setDoc currentDoc

app.ports.setPendingHtml.subscribe (html) ->

  if html?
    wrapperNode = document.createElement "div"
    wrapperNode.innerHTML = html

    doc = DocEditor.docFromNode wrapperNode

    sync.saveDocWithSnapshot doc, {html}, (doc, snapshot) ->
      sync.putSetting "currentDocId", doc.id, ->
        app.ports.loadDoc.send [doc.id, doc]

withEditor = (callback) ->
  if editor?
    callback editor
  else
    # If the editor isn't initialized yet, yield and try again until it's ready.
    setTimeout (-> withEditor callback), 0

########################

sync = new DreamSync()

sync.getCurrentDocId (id) ->
  if id?
    sync.getDoc id, (doc) ->
      app.ports.loadDoc.send [id, doc]
  else
    # Passing an id with a null doc triggers loading the intro doc.
    app.ports.loadDoc.send [DreamSync.getRandomSha(), null]

setUpEditor = (iframe) ->
  editor = new DocEditor iframe, (updatedDoc) ->
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
