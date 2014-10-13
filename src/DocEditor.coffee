## DocEditor
#
# Wraps an iframe and does the following:
#
# 1. Enables designMode on the iframe
# 2. Whenever the iframe's contents change, computes the structure of the
#    new document (title, chapters, etc.) and passes them to a callback.
# 3. Writes to the iframe whenever a new doc is received.
module.exports = class DocEditor
  doc: null

  constructor: (iframe, onChange) ->
    contentDocument = iframe.contentDocument ? iframe.contentWindow.document
    contentDocument.designMode = "on"

    changeObserver = new MutationObserver (mutations) =>
      if @doc == null
        onChange null
      else
        doc = DocEditor.docFromNode contentDocument.firstChild
        doc.id = @doc.id # TODO decouple id from doc

        onChange doc

    changeObserver.observe contentDocument, mutationObserverOptions

    @contentDocument = contentDocument
    @changeObserver  = changeObserver

  setDoc: (doc) ->
    docChanged =
      (doc == null && @doc != null) ||
      (doc != null && @doc == null) ||
      (doc.id != @doc.id)

    if docChanged
      html = if doc == null then "" else doc.html

      writeToIframeDocument @contentDocument, html, onWriteSuccess, onWriteError

    @doc = doc

  @docFromNode = (node) ->
    html     = node.innerHTML
    title    = node.querySelector("h1")?.textContent ? ""
    chapters = for heading in node.querySelectorAll("h2")
      {heading: heading.textContent}

    {html, title, chapters}

  dispose: ->
    @changeObserver.disconnect()

onWriteSuccess = (->)
onWriteError   = (err) ->
    console.error "Error while trying to write to editor", err
    throw new Error err

# The options used to configure the mutation observer that watches the iframe.
mutationObserverOptions = {
  subtree:       true
  childList:     true
  attributes:    true
  characterData: true
}

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
