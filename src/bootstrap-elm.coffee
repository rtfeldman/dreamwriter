require "promises-done-polyfill"

Editor     = require "./Editor.coffee"
DreamSync  = require "./DreamSync.coffee"
DreamNotes = require "./DreamNotes.coffee"
DocImport  = require "./DocImport.coffee"
FileIO     = require "./FileIO.coffee"
countWords = require "./WordCount.coffee"

blankDoc = {id: "", title: "", description: "", chapters: [], creationTime: 0, lastModifiedTime: 0, words: 0}

app = Elm.fullscreen Elm.App, {
  loadAsCurrentDoc: blankDoc
  setChapters: []
  updateChapter: { id: "", heading: "", words: 0, creationTime: 0, lastModifiedTime: 0, snapshotId: ""}
  setTitle: ""
  setDescription: ""
  listDocs: []
  listNotes: []
  setFullscreen: false
  setCurrentNote: {id: "", title: "", snapshotId: "", creationTime: 0, lastModifiedTime: 0}
  putSnapshot: {id: "", html: "", text: ""}
}

# This will be initialized once a connection to the db has been established.
sync = null
notes = null

# Looks up the doc and snapshot associated with the given docId,
# writes the snapshot to the editor, and tells Elm about the new currentDocId
loadDocId = (docId) ->
  sync.getDoc(docId).done loadAsCurrentDoc

loadAsCurrentDoc = (doc) ->
  app.ports.loadAsCurrentDoc.send doc

  setUpEditor "edit-title", doc.title, false, (mutations, node) ->
    sync.getDoc(doc.id).done (doc) ->
      doc.title = node.textContent
      sync.saveDoc(doc).done -> app.ports.setTitle.send doc.title

  setUpEditor "edit-description", doc.description, false, (mutations, node) ->
    sync.getDoc(doc.id).done (doc) ->
      doc.description = node.textContent
      sync.saveDoc(doc).done -> app.ports.setDescription.send doc.description

  doc.chapters.forEach setUpChapter

setUpChapter = (chapter) ->
  chapterId = chapter.id
  headingEditorElemId = "edit-chapter-heading-#{chapterId}"
  bodyEditorElemId    = "edit-chapter-body-#{chapterId}"

  # If you delete the chapter's body and heading, assume you want it gone.
  # (If you didn't, you can just re-add it; there couldn't have been data loss.)
  wasChapterRemoved = (words, mutations) ->
    # Returns true iff there's no text content in either the body or the heading
    words == 0 &&
      # Don't do this if nodes were added or removed; otherwise we can get false
      # positives while the chapter is being created, causing it to be deleted.
      (!mutations.some ({addedNodes, removedNodes}) ->
        addedNodes.length > 0 || removedNodes.length > 0) &&
      !document.getElementById(headingEditorElemId).textContent.match(/\S/) &&
      !document.getElementById(bodyEditorElemId).textContent.match(/\S/)

  editorHeadingPromise = setUpEditor headingEditorElemId, chapter.heading, false, (mutations, node) ->
    sync.getCurrentDoc().done (doc) ->
      heading = node.textContent

      chapter.heading = heading
      chapter.words   = countWords heading

      doc.chapters = for existingChapter in doc.chapters
        if existingChapter.id == chapter.id
          chapter
        else
          existingChapter

      if wasChapterRemoved chapter.words, mutations
        deleteChapter chapter
      else
        sync.saveDoc(doc).done -> app.ports.updateChapter.send chapter

  editorBodyPromise = new Promise (resolve, reject) ->
    sync.getSnapshot(chapter.snapshotId).done (snapshot) ->
      setUpEditor bodyEditorElemId, snapshot.html, true, (mutations, node) ->
        snapshotId    = chapter.snapshotId
        html          = node.innerHTML
        text          = node.textContent
        chapter.words = countWords text

        if wasChapterRemoved chapter.words, mutations
          deleteChapter chapter
        else
          sync.getCurrentDoc().done (doc) ->
            sync.saveSnapshot({id: snapshotId, html})
              .then (->
                  app.ports.putSnapshot.send {id: snapshotId, html, text}
                  app.ports.updateChapter.send chapter

                  resolve()
                ), reject

  Promise.all [editorHeadingPromise, editorBodyPromise]

app.ports.newChapter.subscribe ->
  sync.getCurrentDoc().done (doc) ->
    sync.addChapter(doc,
      DocImport.blankChapterHeading, DocImport.blankChapterHtml).done (doc) ->
        app.ports.setChapters.send doc.chapters

        newChapter = doc.chapters[doc.chapters.length - 1]
        setUpChapter(newChapter).done (editorHeading, editorBody) ->
          scrollToChapterId newChapter.id

          # TODO refactor this to just make a Range and then invoke range.selectNode() on this node,
          # rather than doing execCommand "selectall"
          document.getElementById("edit-chapter-heading-#{newChapter.id}").focus()
          document.execCommand "selectall"

saveHtmlAndLoadDoc = (html) ->
  sync.saveFreshDoc(DocImport.docFromHtml html).done loadAsCurrentDoc

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

getEditorFor = (elem, enableRichText, onMutate) ->
  if editors.has elem
    editor = editors.get elem
    editor.onChange = onMutate
    editor
  else
    editor = new Editor elem, mutationObserverOptions, enableRichText, onMutate
    editors.set elem, editor
    editor

setUpEditor = (id, html, enableRichText, onMutate) ->
  whenPresent((-> document.getElementById id), 10000)
    .then ((elem) -> getEditorFor(elem, enableRichText, onMutate).writeHtml html, true),
          ((err)  -> console.error "Could not write after 10,000 attempts:", id, html)

refreshDocList = -> sync.listDocs().done (docs) ->
  app.ports.listDocs.send docs

scrollToChapterId = (chapterId) ->
  editorFrame    = document.getElementById("editor-frame")
  editorHeader   = document.getElementById("editor-header")
  chapterHeading = document.getElementById("edit-chapter-heading-#{chapterId}")

  editorFrame.scrollTop = chapterHeading.offsetTop - editorHeader.offsetHeight

deleteChapter = (chapter) ->
  sync.deleteChapter(chapter).done (newChapters) ->
    app.ports.setChapters.send newChapters

app.ports.setCurrentDocId.subscribe (newDocId) ->
  if newDocId?
    # TODO Ideally this would not be Race Condition City...
    sync.getCurrentDocId().done (currentDocId) ->
      if currentDocId != newDocId
        sync.saveCurrentDocId(newDocId).done ->
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
  newNote = {title: "Brilliant Note"}
  html = "<p><br/></p>"

  sync.saveNoteWithSnapshot(newNote, html).done (note) ->
    app.ports.setCurrentNote.send note
    console.debug "TODO load up the note editor with the current html"

app.ports.execCommand.subscribe (command) ->
  document.execCommand command, false, null

app.ports.searchNotes.subscribe (query) ->
  query = document.getElementById("notes-search-text").value

  notes.search(query).done app.ports.listNotes.send

app.ports.openFromFile.subscribe ->
  fileChooserAttributes = {accept: "text/html", multiple: "true"}

  FileIO.showFileChooser(fileChooserAttributes).done (files) ->
    saveAndLoadFromFile = (file) ->
      new Promise (resolve, reject) ->
        saveAndResolve = (doc) ->
          sync.saveFreshDoc(doc).done (newCurrentDoc) ->
            app.ports.loadAsCurrentDoc.send newCurrentDoc
            resolve()

        readDocFromFile(file).then saveAndResolve, reject

    Promise.all(saveAndLoadFromFile file for file in files).done refreshDocList

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

DreamSync.connect().done (instance) ->
  sync = instance

  notes = new DreamNotes sync

  [{
    title: 'Twelfth Night',
    body: 'If music be the food of love, play on'
  }, {
    title: 'Macbeth',
    body: 'When shall we three meet again, In thunder, lightning, or in rain?'
  }, {
    title: 'Richard III',
    body: 'Now is the winter of our discontent, Made glorious summer by this sun of York;'
  }].forEach ({title, body}) ->
    notes.save {title}, body

  # Initialize the app based on the stored currentDocId
  sync.getCurrentDocId().done (id) ->
    if id?
      loadDocId id
    else
      saveHtmlAndLoadDoc DocImport.introDocHtml

  refreshDocList()