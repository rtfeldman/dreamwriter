saveAs = require "FileSaver.js"

module.exports =
  showFileChooser: (attributes = {}) ->
    new Promise (resolve, reject) ->
      fileChooser = document.createElement "input"
      clickEvent  = document.createEvent "MouseEvents"

      fileChooser.setAttribute "type", "file"
  
      for name, value of attributes
        fileChooser.setAttribute name, value

      fileChooser.addEventListener "change", (event) ->
        files = fileChooser.files

        # Self-destruct now that we're no longer needed.
        document.body.removeChild fileChooser

        resolve files

      document.body.appendChild fileChooser

      clickEvent.initMouseEvent "click", true, true, window, 1, 0, 0, 0, 0, false, false, false, false, 0, null

      fileChooser.dispatchEvent clickEvent

  readTextFromFile: (file) ->
    new Promise (resolve, reject) ->
      reader = new FileReader

      reader.onerror = reject
      reader.onabort = reject
      reader.onload  = resolve

      reader.readAsText file

  saveAs: saveAs