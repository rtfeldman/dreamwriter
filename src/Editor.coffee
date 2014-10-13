## DocEditor
#
# Wraps an iframe and does the following:
#
# 1. Enables designMode on the iframe
# 2. Whenever the iframe's contents change, computes the structure of the
#    new document (title, chapters, etc.) and passes them to a callback.
# 3. Writes to the iframe when requested
module.exports = class DocEditor
  constructor: (iframe, @mutationObserverOptions, onChange) ->
    contentDocument = iframe.contentDocument ? iframe.contentWindow.document
    contentDocument.designMode = "on"

    @contentDocument  = contentDocument
    @mutationObserver = new MutationObserver (mutations) =>
      onChange mutations, contentDocument.firstChild

    @enableMutationObserver()

  writeHtml: (html) =>
    @withoutMutationObserver =>
      writeToIframeDocument @contentDocument, html, onWriteSuccess, onWriteError

  withoutMutationObserver: (runLogic) =>
    @disableMutationObserver()

    try
      runLogic()
    finally
      @enableMutationObserver @contentDocument

  enableMutationObserver: =>
    @mutationObserver.observe @contentDocument, @mutationObserverOptions

  disableMutationObserver: ->
    @mutationObserver.disconnect()

onWriteSuccess = (->)
onWriteError   = (err) ->
    console.error "Error while trying to write to editor", err
    throw new Error err

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
