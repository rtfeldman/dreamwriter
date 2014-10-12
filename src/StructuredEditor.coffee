## StructuredEditor
#
# Wraps an iframe and does the following:
#
# 1. Enables designMode on the iframe
# 2. Whenever the iframe's contents change, computes the structure of the
#    new document (title, chapters, etc.) and passes them to a callback.
# 3. Exposes a method to write new content to the iframe.
module.exports = class StructuredEditor
  constructor: (iframe, onChange) ->
    contentDocument = iframe.contentDocument ? iframe.contentWindow.document
    contentDocument.designMode = "on"

    mutationHandler = getMutationHandler contentDocument, onChange
    changeObserver  = new MutationObserver mutationHandler
    changeObserver.observe contentDocument, mutationObserverOptions

    @contentDocument = contentDocument
    @changeObserver  = changeObserver

  write: (html, onSuccess, onError) ->
    writeToIframeDocument @contentDocument, html, onSuccess, onError

  dispose: ->
    @changeObserver.disconnect()

# The options used to configure the mutation observer that watches the iframe.
mutationObserverOptions = {
  subtree:       true
  childList:     true
  attributes:    true
  characterData: true
}

# Returns a handler that will get called whenever the iframe document mutates.
getMutationHandler = (contentDocument, callback) ->
  (mutations) ->
    html     = contentDocument.firstChild.innerHTML
    title    = contentDocument.querySelector("h1")?.textContent ? ""
    chapters = for heading in contentDocument.querySelectorAll("h2")
      {heading: heading.textContent}
    doc      = {title, chapters}

    callback {doc, html}

# Writes the given html to the given iframe document,
# and fires a callback once the write is complete.
writeToIframeDocument = (iframeDocument, html, onSuccess, onError) ->
  switch iframeDocument.readyState
    # "complete" in Chrome/Safari, "uninitialized" in Firefox
    when "complete", "uninitialized"
      try
        iframeDocument.open()
        iframeDocument.write html
        iframeDocument.close()

        onSuccess()
      catch error
        onError error
    else
      # If the iframe isn't ready yet, yield and try again until it is ready.
      setTimeout (->
        writeToIframeDocument iframeDocument, html, onSuccess, onError
      ), 0
