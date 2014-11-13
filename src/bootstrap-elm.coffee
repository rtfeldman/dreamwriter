Editor     = require "./Editor.coffee"
DreamSync  = require "./DreamSync.coffee"
DocImport  = require "./DocImport.coffee"
FileIO     = require "./FileIO.coffee"
countWords = require "./WordCount.coffee"

blankDoc = {id: "", title: "", description: "", chapters: [], creationTime: 0, lastModifiedTime: 0, words: 0}

app = Elm.fullscreen Elm.App, {
  loadAsCurrentDoc: blankDoc
  setChapters: []
  setTitle: ""
  setDescription: ""
  listDocs: []
  listNotes: []
  setFullscreen: false
  putSnapshot: {id: "", html: "", text: ""}
}

# This will be initialized once a connection to the db has been established.
sync = null

# Looks up the doc and snapshot associated with the given docId,
# writes the snapshot to the editor, and tells Elm about the new currentDocId
loadDocId = (docId) ->
  sync.getDoc(docId).then loadAsCurrentDoc

loadAsCurrentDoc = (doc) ->
  app.ports.loadAsCurrentDoc.send doc

  setUpEditor "edit-title", doc.title, (mutations, node) ->
    sync.getDoc(doc.id).then (doc) ->
      doc.title = node.textContent
      sync.saveDoc(doc).then -> app.ports.setTitle.send doc.title

  setUpEditor "edit-description", doc.description, (mutations, node) ->
    sync.getDoc(doc.id).then (doc) ->
      doc.description = node.textContent
      sync.saveDoc(doc).then -> app.ports.setDescription.send doc.description

  doc.chapters.forEach setUpChapter

setUpChapter = (chapter) ->
  chapterId = chapter.id
  headingEditorElemId = "edit-chapter-heading-#{chapterId}"
  bodyEditorElemId    = "edit-chapter-body-#{chapterId}"

  editorHeadingPromise = setUpEditor headingEditorElemId, chapter.heading, (mutations, node) ->
    sync.getCurrentDoc().then (doc) ->
      for currentChapter in doc.chapters
        if currentChapter.id == chapterId
          heading = node.textContent
          currentChapter.heading = heading
          currentChapter.words   = countWords heading

      sync.saveDoc(doc).then -> app.ports.setChapters.send doc.chapters

  editorBodyPromise = new Promise (resolve, reject) ->
    sync.getSnapshot(chapter.snapshotId).then (snapshot) ->
      setUpEditor bodyEditorElemId, snapshot.html, (mutations, node) ->
        snapshotId = chapter.snapshotId
        html       = node.innerHTML
        text       = node.textContent

        sync.getCurrentDoc().then (doc) ->
          sync.saveSnapshot({id: snapshotId, html})
            .then (->
                app.ports.putSnapshot.send {id: snapshotId, html, text}

                # TODO don't update all the chapters...only one chapter is
                # actually changing. Make a port for just updating one chapter.
                updatedChapters = for currentChapter in doc.chapters
                  if currentChapter.id == chapter.id
                    currentChapter.words = countWords html

                  currentChapter

                app.ports.setChapters.send updatedChapters

                resolve()
              ), reject

  Promise.all [editorHeadingPromise, editorBodyPromise]

app.ports.newChapter.subscribe ->
  sync.getCurrentDoc().then (doc) ->
    sync.addChapter(doc,
      DocImport.blankChapterHeading, DocImport.blankChapterHtml).then (doc) ->
        app.ports.setChapters.send doc.chapters

        newChapter = doc.chapters[doc.chapters.length - 1]
        setUpChapter(newChapter).then (editorHeading, editorBody) ->
          scrollToChapterId newChapter.id
          document.getElementById("edit-chapter-heading-#{newChapter.id}").focus()
          document.execCommand "selectall"

saveHtmlAndLoadDoc = (html) ->
  sync.saveFreshDoc(DocImport.docFromHtml html).then loadAsCurrentDoc

readDocFromFile = (file, onSuccess, onError) ->
  new Promise (resolve, reject) ->
    onSuccess = (response) ->
      filename         = file.name ? file.fileName
      lastModifiedTime = if file.lastModifiedDate? then (new Date file.lastModifiedDate).getTime() else undefined
      html             = response.target.result

      resolve DocImport.docFromFile filename, lastModifiedTime, html

    FileIO.readTextFromFile(file).then onSuccess, reject

downloadDoc = (filename, contentType) ->
  whenPresent((-> document.getElementById "document-page"), 10000)
    .then ((elem) ->
      clone = document.getElementById("document-page").cloneNode true

      for editable in clone.querySelectorAll("[contentEditable=true]")
        editable.contentEditable = false
        editable.spellcheck = false

      html = DocImport.wrapInDocMarkup {body: clone.innerHTML}
      FileIO.saveAs new Blob([html], {type: contentType}), filename
    ),
    ((err) -> console.error "Could not download from page after 10,000 attempts"),

# TODO when there's some way to receive a Signal (or something) that a real DOM
# node has been created, replace this hackery with that.
whenPresent = (getElem, attemptsRemaining = 10000) ->
  new Promise (resolve, reject) ->
    elem = getElem()

    if elem?
      resolve elem
    else if attemptsRemaining
      requestAnimationFrame ->
        whenPresent(getElem, attemptsRemaining - 1).then resolve, reject
    else
      reject()

editors = new WeakMap()
mutationObserverOptions =
  { subtree: true, childList: true, attributes: true, characterData: true }

getEditorFor = (elem, onMutate) ->
  if editors.has elem
    editor = editors.get elem
    editor.onChange = onMutate
    editor
  else
    editor = new Editor elem, mutationObserverOptions, onMutate
    editors.set elem, editor
    editor

setUpEditor = (id, html, onMutate) ->
  whenPresent((-> document.getElementById id), 10000)
    .then ((elem) -> getEditorFor(elem, onMutate).writeHtml html, true),
          ((err)  -> console.error "Could not write after 10,000 attempts:", id, html)

refreshDocList = -> sync.listDocs().then (docs) ->
  app.ports.listDocs.send docs

scrollToChapterId = (chapterId) ->
  editorFrame    = document.getElementById("editor-frame")
  editorHeader   = document.getElementById("editor-header")
  chapterHeading = document.getElementById("edit-chapter-heading-#{chapterId}")

  editorFrame.scrollTop = chapterHeading.offsetTop - editorHeader.offsetHeight

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

app.ports.downloadDoc.subscribe ({filename, contentType}) -> downloadDoc filename, contentType

app.ports.printDoc.subscribe -> window.print()

app.ports.navigateToChapterId.subscribe scrollToChapterId

app.ports.navigateToTitle.subscribe ->
  document.getElementById("editor-frame").scrollTop = 0

app.ports.newNote.subscribe ->
  console.debug "TODO: create a new note from template, persist it, then send it over."

app.ports.execCommand.subscribe (command) ->
  document.execCommand command, false, null

app.ports.searchNotes.subscribe (query) ->
  # TODO just have the signal send this along
  query = document.getElementById("notes-search-text").value

  notes = [
    {id: "1", title: "Awesome Note", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
    {id: "2", title: "Great Scott!", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
    {id: "3", title: "This note has a ridiculously long title for basically no reason at all", snapshotId: "1234", creationTime: 0, lastModifiedTime: 0}
  ]

  app.ports.listNotes.send notes

app.ports.openFromFile.subscribe ->
  fileChooserAttributes = {accept: "text/html", multiple: "true"}

  FileIO.showFileChooser(fileChooserAttributes).then (files) ->
    saveAndLoadFromFile = (file) ->
      new Promise (resolve, reject) ->
        saveAndResolve = (doc) ->
          sync.saveFreshDoc(doc).then (newCurrentDoc) ->
            app.ports.loadAsCurrentDoc.send newCurrentDoc
            resolve()

        readDocFromFile(file).then saveAndResolve, reject

    Promise.all(saveAndLoadFromFile file for file in files).then refreshDocList

isFullscreen = -> !!(document.mozFullScreenElement ? document.webkitCurrentFullScreenElement?)

requestFullScreen = (document.body.requestFullScreen ? document.body.webkitRequestFullScreen ? document.body.mozRequestFullScreen).bind document.body
exitFullscreen = (document.cancelFullScreen ? document.webkitCancelFullScreen ? document.mozCancelFullScreen ? document.exitFullScreen).bind document

onFullscreenChange = -> app.ports.setFullscreen.send isFullscreen()

document.addEventListener "fullscreenchange",       onFullscreenChange
document.addEventListener "webkitfullscreenchange", onFullscreenChange
document.addEventListener "mozfullscreenchange",    onFullscreenChange

app.ports.fullscreen.subscribe (desiredMode) ->
  if desiredMode
    requestFullScreen Element.ALLOW_KEYBOARD_INPUT
  else
    exitFullscreen()

DreamSync.connect().then (instance) ->
  sync = instance

  # Initialize the app based on the stored currentDocId
  sync.getCurrentDocId().then (id) ->
    if id?
      loadDocId id
    else
      saveHtmlAndLoadDoc DocImport.introDocHtml

  refreshDocList()