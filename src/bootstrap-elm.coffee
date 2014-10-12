StructuredEditor = require "./DocEditor.coffee"
sha1             = require "sha1"

app = Elm.fullscreen Elm.App, {
  editDoc: null
  loadDoc: ["", null]
}

getRandomSha = -> sha1 "#{Math.random()}"[0..16]

# This will be initialized once the iframe is added to the DOM.
editor = null

##### update editor #####

app.ports.setCurrentDoc.subscribe (currentDoc) ->
  withEditor (editor) -> editor.setDoc currentDoc

withEditor = (callback) ->
  if editor?
    callback editor
  else
    # If the editor isn't initialized yet, yield and try again until it's ready.
    setTimeout (-> withEditor callback), 0

########################

setUpEditor = (iframe) ->
  app.ports.loadDoc.send [getRandomSha(), null]

  editor = new StructuredEditor iframe, (updatedDoc) ->
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
