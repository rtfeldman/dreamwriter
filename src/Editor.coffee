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

    @elem.addEventListener "keyup", @handleKeyup

    @enableMutationObserver()

  writeHtml: (html, skipObserver, onSuccess = (->), onError = onWriteError) =>
    @runWithOptionalObserver skipObserver, =>
      @elem.innerHTML = html
      onSuccess()

  getHtml: ->
    @elem.innerHTML

  handleKeyup: (event) =>
    selection = window.getSelection()
    range     = selection.getRangeAt 0
    textNode  = range.commonAncestorContainer

    # TODO preventDefault on ctrl+S and cmd+S
    # TODO intelligently handle Up Arrow at the beginning of a section
    # TODO intelligently handle Down Arrow at the end of a section

    # The user just typed something and has a collapsed selection.
    if range.collapsed && @elem.contains textNode
      # The character right before the caret
      prevChar = textNode.textContent[range.endOffset - 1]

      switch prevChar
        when "\""
          @applySmartQuote      selection
        when "'"
          @applySmartApostrophe selection
        when "-"
          # If the user typed --, convert to em dash
          if prevChar == textNode.textContent[range.endOffset - 2]
            @applySmartEmDash   selection

  applySmartQuote: (selection) =>
  applySmartApostrophe: (selection) =>
  applySmartEmDash: (selection) =>

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
