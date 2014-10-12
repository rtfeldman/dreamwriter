
module.exports = class StructuredEditor
  constructor: (@iframe, onChange) ->
    contentDocument = iframe.contentDocument ? iframe.contentWindow.document
    contentDocument.designMode = "on"

    changeObserver = new MutationObserver getMutationHandler(contentDocument, onChange)
    changeObserver.observe contentDocument, changeObserverOptions

    @contentDocument = contentDocument
    @changeObserver  = changeObserver

  write: (html, onSuccess, onError) ->
    writeToIframeDocument @contentDocument, html, onSuccess, onError

  dispose: ->
    @changeObserver.disconnect()

changeObserverOptions = {
  subtree:       true
  childList:     true
  attributes:    true
  characterData: true
}

getMutationHandler = (contentDocument, callback) ->
  (mutations) ->
    html     = contentDocument.firstChild.innerHTML
    title    = contentDocument.querySelector("h1")?.textContent ? ""
    chapters = for heading in contentDocument.querySelectorAll("h2")
      {heading: heading.textContent}
    doc      = {title, chapters}

    callback {doc, html}

writeToIframeDocument = (iframeDocument, html, onSuccess = (->), onError = (->)) ->
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
      setTimeout (-> writeToIframeDocument iframeDocument, html, onSuccess, onError), 0
