Editor    = require "./Editor.coffee"
DreamSync = require "./DreamSync.coffee"
DocImport = require "./DocImport.coffee"
saveAs    = require "FileSaver.js"

blankDoc = {id: "", title: "", chapters: [], creationTime: 0, lastModifiedTime: 0}

app = Elm.fullscreen Elm.App, {
  loadAsCurrentDoc: blankDoc
  listDocs: []
}

# This will be initialized once a connection to the db has been established.
sync = null

# This will be initialized once the iframe has been added to the DOM.
maybeEditor = null

withEditor = (callback) ->
  if maybeEditor?
    callback maybeEditor
  else
    # If the editor isn't initialized yet, yield and try again until it's ready.
    setTimeout (-> withEditor callback), 0

# Looks up the doc and snapshot associated with the given docId,
# writes the snapshot to the editor, and tells Elm about the new currentDocId
loadDocId = (docId) ->
  sync.getDoc(docId).then (doc) ->
    sync.getSnapshot(doc.snapshotId).then (snapshot) ->
      app.ports.loadAsCurrentDoc.send doc
      withEditor (editor) ->
        editor.writeHtml snapshot.html, true

saveHtmlAndLoadDoc = (html) ->
  inferredDoc = DocImport.docFromHtml html

  sync.saveDocWithSnapshot(inferredDoc, {html})
    .then app.ports.loadAsCurrentDoc.send

setUpEditor = (iframe) ->
  mutationObserverOptions =
    { subtree: true, childList: true, attributes: true, characterData: true }

  maybeEditor = new Editor iframe, mutationObserverOptions, (mutations, node) ->
    sync.getCurrentDocId().then (currentDocId) ->
      sync.getDoc(currentDocId).then (doc) ->
        doc.title    = DocImport.inferTitleFrom(node) ? doc.title ? ""
        doc.chapters = DocImport.inferChaptersFrom(node)

        sync.saveDocWithSnapshot(doc, {html: node.innerHTML})
          .then app.ports.loadAsCurrentDoc.send

showFileChooser = ->
  new Promise (resolve, reject) ->
    fileChooser = document.createElement "input"
    clickEvent  = document.createEvent "MouseEvents"

    for name, value of {type: "file", accept: "text/html", multiple: "true"}
      fileChooser.setAttribute name, value

    fileChooser.addEventListener "change", (event) ->
      files = fileChooser.files

      # Self-destruct now that we're no longer needed.
      document.body.removeChild fileChooser

      resolve files

    document.body.appendChild fileChooser

    clickEvent.initMouseEvent "click", true, true, window, 1, 0, 0, 0, 0, false, false, false, false, 0, null

    fileChooser.dispatchEvent clickEvent

readDocFromFile = (file, onSuccess, onError) ->
  new Promise (resolve, reject) ->
    reader = new FileReader

    reader.onerror = reject
    reader.onabort = reject
    reader.onload = (response) ->
      filename         = file.name ? file.fileName
      lastModifiedTime = if file.lastModifiedDate? then (new Date file.lastModifiedDate).getTime() else undefined
      html             = response.target.result
      doc              = DocImport.docFromFile filename, lastModifiedTime, html

      resolve {doc, html}

    reader.readAsText file

##### iframe appearance hack #####

# We need to set up the iframe as soon as it appears, but we don't have a way
# to detect when that will happen, so we use a mutation observer to watch
# for it and set it up as soon as it appears.

((document, setUpEditor) ->
  iframeAppearanceObserver = new MutationObserver (mutations) ->
    setTimeout (->
      requestAnimationFrame ->
        console.log document.getElementById("edit-preface")
    ), 0

    isEditor = (node) -> node.nodeType != 3 && node.getAttribute("contentEditable")
    setUpEditors = (nodes) ->
      for node in nodes
        if isEditor node
          setUpEditor node
        else
          setUpEditors node.children

    for mutation in mutations
      setUpEditors mutation.addedNodes

    # TODO it's a problem that this never disconnects...will register all sorts of
    # duplicate events during editing :(
    # maybe we just want to do this for the first editor? And then do the others
    # differently? Erg...

  iframeAppearanceObserver.observe document.body, {attributes: true, childList: true}
)(document, setUpEditor)

##################################

refreshDocList = -> sync.listDocs().then app.ports.listDocs.send

app.ports.setCurrentDocId.subscribe (newDocId) ->
  if newDocId?
    # TODO Ideally this would not be Race Condition City...
    sync.getCurrentDocId().then (currentDocId) ->
      if currentDocId != newDocId
        sync.saveCurrentDocId(newDocId).then ->
          loadDocId newDocId

app.ports.newDoc.subscribe ->
  saveHtmlAndLoadDoc DocImport.blankDocHtml
  refreshDocList()

app.ports.downloadDoc.subscribe ({filename, contentType}) ->
  withEditor (editor) ->
    saveAs new Blob([editor.getHtml()], {type: contentType}), filename

app.ports.openFromFile.subscribe ->
  showFileChooser().then (files) ->
    saveAndLoadFromFile = (file) ->
      new Promise (resolve, reject) ->
        saveAndResolve = ({doc, html}) ->
          sync.saveDocWithSnapshot(doc, {html}).then (newCurrentDoc) ->
            app.ports.loadAsCurrentDoc.send newCurrentDoc
            resolve()

        readDocFromFile(file).then saveAndResolve, reject

    Promise.all(saveAndLoadFromFile file for file in files).then refreshDocList

DreamSync.connect().then (instance) ->
  sync = instance

  # Initialize the app based on the stored currentDocId
  sync.getCurrentDocId().then (id) ->
    if id?
      loadDocId id
    else
      saveHtmlAndLoadDoc DocImport.introDocHtml

  refreshDocList()