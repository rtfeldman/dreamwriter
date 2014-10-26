## Editor
#
# Wraps a contentEditable element and does the following:
#
# 1. Whenever the element's contents change, computes the structure of the
#    new document (title, chapters, etc.) and passes them to a callback.
# 2. Writes to the element when requested, optionally while disabling the 
#    mutation observer to avoid spurious updates.
module.exports = class Editor
  constructor: (@elem, @mutationObserverOptions, @onChange) ->
    @mutationObserver = new MutationObserver (mutations) =>
      @onChange mutations, @elem

    @enableMutationObserver()

  writeHtml: (html, skipObserver, onSuccess = (->), onError = onWriteError) =>
    @runWithOptionalObserver skipObserver, =>
      @elem.innerHTML = html
      onSuccess()

  getHtml: ->
    @elem.innerHTML

  execCommand: (command, skipObserver) =>
    @runWithOptionalObserver skipObserver, =>
      @elem.execCommand command

  runWithOptionalObserver: (skipObserver, runLogic) =>
    if skipObserver
      runLogic()
    else
      @disableMutationObserver()

      try
        runLogic()
      finally
        @enableMutationObserver @elem

  enableMutationObserver: =>
    @mutationObserver.observe @elem, @mutationObserverOptions

  disableMutationObserver: ->
    @mutationObserver.disconnect()

onWriteError = (err) ->
    console.error "Error while trying to write to editor", err
    throw new Error err
