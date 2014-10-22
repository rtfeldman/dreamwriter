Editor    = require "./Editor.coffee"
DreamSync = require "./DreamSync.coffee"
DocImport = require "./DocImport.coffee"
saveAs    = require "FileSaver.js"

blankDoc = {id: "", title: "", description: "", chapters: [], creationTime: 0, lastModifiedTime: 0, words: 0}

app = Elm.fullscreen Elm.App, {
  loadAsCurrentDoc: blankDoc
  listDocs: []
  listNotes: []
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
    app.ports.loadAsCurrentDoc.send doc

    doc.chapters.forEach (chapter) ->
      write "edit-chapter-heading-#{chapter.id}", chapter.heading

      sync.getSnapshot(chapter.snapshotId).then (snapshot) ->
        write "edit-chapter-body-#{chapter.id}", snapshot.html

saveHtmlAndLoadDoc = (html) ->
  sync.saveFreshDoc(DocImport.docFromHtml html)
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

      resolve DocImport.docFromFile filename, lastModifiedTime, html

    reader.readAsText file


whenPresent = (getElem, onSuccess, onError, attemptsRemaining = 10000) ->
  elem = getElem()

  if elem?
    onSuccess elem
  else if attemptsRemaining
    requestAnimationFrame ->
      whenPresent getElem, onSuccess, onError, attemptsRemaining - 1
  else
    onError()

write = (id, html) ->
  whenPresent (-> document.getElementById id),
    ((elem) -> elem.innerHTML = html),
    ((err) -> console.error "Could not write after 10,000 attempts:", id, html),
    10000

refreshDocList = -> sync.listDocs().then (docs) ->
  app.ports.listDocs.send docs

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
  whenPresent (-> document.getElementById "document-page"),
    ((elem) ->
      clone = document.getElementById("document-page").cloneNode true

      for editable in clone.querySelectorAll("[contentEditable=true]")
        editable.contentEditable = false
        editable.spellcheck = false

      html = DocImport.wrapInDocMarkup {body: clone.innerHTML}
      saveAs new Blob([html], {type: contentType}), filename
    ),
    ((err) -> console.error "Could not download from page after 10,000 attempts"),
    10000

app.ports.printDoc.subscribe ->
  window.print()

app.ports.navigateToChapterId.subscribe (chapterId) ->
  editorFrame    = document.getElementById("editor-frame")
  editorHeader   = document.getElementById("editor-header")
  chapterHeading = document.getElementById("edit-chapter-heading-#{chapterId}")

  editorFrame.scrollTop = chapterHeading.offsetTop - editorHeader.offsetHeight

app.ports.navigateToTitle.subscribe ->
  document.getElementById("editor-frame").scrollTop = 0

app.ports.newNote.subscribe ->
  console.debug "TODO: create a new note from template, persist it, then send it over."

app.ports.searchNotes.subscribe (query) ->
  # TODO just have the signal send this along
  query = document.getElementById("notes-search-text").value

  console.debug "TODO: search notes database for", query
  notes = [
    {id: "1", title: "Awesome Note", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
    {id: "2", title: "Great Scott!", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
    {id: "3", title: "This note has a ridiculously long title for basically no reason at all", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
  ]

  app.ports.listNotes.send notes

app.ports.openFromFile.subscribe ->
  showFileChooser().then (files) ->
    saveAndLoadFromFile = (file) ->
      new Promise (resolve, reject) ->
        saveAndResolve = (doc) ->
          sync.saveFreshDoc(doc).then (newCurrentDoc) ->
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