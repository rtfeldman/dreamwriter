## Editor
#
# Wraps a contentEditable element and does the following:
#
# 1. Whenever the element's contents change, computes the structure of the
#    new document (title, chapters, etc.) and passes them to a callback.
# 2. Writes to the element when requested, optionally while disabling the 
#    mutation observer to avoid spurious updates.
Medium = require "./medium.js"

emDash = '—'

module.exports = class Editor
  constructor: (@elem, @mutationObserverOptions, enableRichText, @onChange) ->
    @mutationObserver = new MutationObserver (mutations) =>
      @onChange mutations, @elem

    try
      @medium = new Medium
        element: @elem
        pasteAsText: false
        mode: if enableRichText then Medium.richMode else Medium.inlineMode
    catch err
      console.error "Error setting up Medium:", err
      throw err

    @elem.addEventListener "keydown", @handleKeydown

    @enableMutationObserver()

  writeHtml: (html, skipObserver, onSuccess = (->), onError = onWriteError) =>
    @runWithOptionalObserver skipObserver, =>
      @medium.value html
      onSuccess()

  getHtml: ->
    @medium.value()

  handleKeydown: (event) =>
    useSmartHandler = (handler) =>
      selection   = window.getSelection()
      range       = selection.getRangeAt 0
      caretOffset = range.startOffset
      textNode    = range.commonAncestorContainer

      handler.apply this, [event, caretOffset, textNode]

    # TODO intelligently handle Up Arrow at the beginning of a section
    # TODO intelligently handle Down Arrow at the end of a section
    switch event.keyCode
      when 222 then useSmartHandler @applySmartQuote
      when 189 then useSmartHandler @applySmartEmDash
      when 83
        # Disable Cmd+S and Ctrl+S
        if event.metaKey || event.ctrlKey
          event.preventDefault()

  applySmartQuote: (event, caretOffset, textNode) =>
    event.preventDefault()

    precededByWord = textNode.textContent[caretOffset - 1]?.match /\S/

    char = if event.shiftKey
      if precededByWord then "”" else "“"
    else
      if precededByWord then "’" else "‘"

    @replaceWith textNode, caretOffset, caretOffset, char

  applySmartEmDash: (event, caretOffset, textNode) =>
    # The user typed "--", which we will now convert to an em dash.
    if "-" == textNode.textContent[caretOffset - 1]
      event.preventDefault()

      @replaceWith textNode, caretOffset - 1, caretOffset, emDash

  replaceWith: (textNode, startOffset, endOffset, html, callback) =>
    selection = window.getSelection()
    range     = selection.getRangeAt 0

    # We need to have some text selected, so that inserting HTML overrides
    # the existing content. Thus, if the range is collapsed, expand it.
    if range.collapsed
      range.setStart textNode, startOffset
      range.setEnd   textNode, endOffset

    @medium.insertHtml html, callback

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

getCaretOffset = ->
  window.getSelection().getRangeAt(0)?.startOffset
