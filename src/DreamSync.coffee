## DreamSync
#
# Handles synchronizing data to/from IndexedDB, remote, etc.

dbjs       = require "db.js"
sha1       = require "sha1"
dbOptions  = require "./idb-options.json"
countWords = require "./WordCount.coffee"
Dropbox    = require "./dropbox.js"

module.exports = class DreamSync
  constructor: (@db) ->
    @dreamBox = null

  @connect: ->
    new Promise (resolve, reject) ->
      dbjs.open(dbOptions).then ((conn) -> resolve new DreamSync conn), reject

  @getRandomSha: -> sha1 "#{Math.random()}"[0..16]

  # This can be called either on page load (if there's a token in localStorage)
  # or mid-session if the user decides to enable Dropbox syncing.
  connectToDropbox: =>
    DreamBox.auth().then (dreamBox) =>
      @dreamBox = dreamBox

      # TODO sync with dropbox, reconcile file changes, etc!

      # TODO move this logic into appropriate saveFooAndBar functions,
      # and reorganize it to not just write an entire file every single time...
      console.log "Auth'd with Dropbox:", dreamBox
      dreamBox.writeFile "Alice.html", document.getElementById("editor").innerHTML, (error, stat) ->
        console.log "writeFile:", error, stat

  disconnectFromDropbox: =>
    @dreamBox = null

  getCurrentDocId:       => @getSetting  "currentDocId"
  saveCurrentDocId: (id) => @saveSetting "currentDocId", id

  getCurrentNoteId:       => @getSetting  "currentNoteId"
  saveCurrentNoteId: (id) => @saveSetting "currentNoteId", id

  saveSetting: (id, value) => @db.settings.update {id, value}
  getSetting:  (id) =>
    new Promise (resolve, reject) =>
      @db.settings.get(id).then ((result) -> resolve result?.value), reject

  listDocs: => @db.docs.query().all().execute()

  getDoc:      (id) => @db.docs.get      id
  getNote:     (id) => @db.notes.get     id
  getSnapshot: (id) => @db.snapshots.get id

  getNotes: (ids) =>
    @db.notes.query().filter((note) -> note.id in ids).execute()

  getCurrentDoc: =>
    new Promise (resolve, reject) =>
      @getCurrentDocId().then (id) =>
        @getDoc(id).then resolve, reject

  getCurrentNote: =>
    new Promise (resolve, reject) =>
      @getCurrentNoteId().then (id) =>
        @getNote(id).then resolve, reject

  saveDoc:      (doc)      => @db.docs.update      doc
  saveNote:     (note)     => @db.notes.update     note
  saveSnapshot: (snapshot) => @db.snapshots.update snapshot

  saveNotesIndex: (index) => @saveSetting "notesIndex", index
  getNotesIndex:          => @getSetting  "notesIndex"

  addChapter: (doc, heading, html) =>
    snapshot = {id: DreamSync.getRandomSha(), html}

    currentTime = new Date().getTime()

    chapter = {
      id:               DreamSync.getRandomSha()
      heading:          heading
      lastModifiedTime: currentTime
      creationTime:     currentTime
      snapshotId:       snapshot.id
      words:            countWords(heading)
    }

    doc.chapters.push chapter

    new Promise (resolve, reject) =>
      Promise.all([
        (@saveSnapshot snapshot)
        (@saveDoc      doc)
      ]).then (-> resolve doc), reject

  # Mutates the LIVING HELL out of the doc you give it, so watch out!
  # Assumes the chapters on the doc you give it will have an "html" field,
  # which this deletes before persisting those fields as snapshots.
  # This may not be pretty, but it sure is fast!
  saveFreshDoc: (doc) =>
    doc.lastModifiedTime   = new Date().getTime()
    doc.creationTime     ||= doc.lastModifiedTime
    doc.id               ||= DreamSync.getRandomSha()

    snapshotPromises = for chapter in doc.chapters
      snapshot = {id: DreamSync.getRandomSha(), html: chapter.html}
      delete chapter.html

      chapter.lastModifiedTime    = doc.lastModifiedTime
      chapter.creationTime      ||= doc.creationTime
      chapter.id                ||= DreamSync.getRandomSha()
      chapter.snapshotId          = snapshot.id
      chapter.words               = countWords snapshot.html

      @saveSnapshot snapshot

    allPromises = snapshotPromises.concat [@saveDoc doc]

    new Promise (resolve, reject) ->
      onSuccess = -> resolve doc
      onError   = ->
        console.error "doc that could not be saved:", doc
        throw new Error "Unable to save doc #{JSON.stringify doc}"

      Promise.all(allPromises).then onSuccess, onError

  saveDocWithSnapshot: (doc, snapshot) ->
    if doc.id?
      new Promise (resolve, reject) =>
        @getDoc(doc.id).then (existingDoc) =>
          if existingDoc.lastModifiedTime > doc.lastModifiedTime
            # TODO handle this by re-rendering etc
            alert "Your document is out of sync! Please refresh."
          else
            persistDocAndSnapshot(@db, doc, snapshot).then resolve, reject
    else
      doc.id = DreamSync.getRandomSha()
      persistDocAndSnapshot @db, doc, snapshot

  saveNoteWithSnapshot: (note, html) ->
    snapshot = {id: DreamSync.getRandomSha(), html}

    if note.id?
      new Promise (resolve, reject) =>
        @getNote(note.id).then (existingNote) =>
          if existingNote? && existingNote.lastModifiedTime > note.lastModifiedTime
            # TODO handle this by re-rendering etc
            alert "Your note is out of sync! Please refresh."
          else
            persistNoteAndSnapshot(@db, note, snapshot).then resolve, reject
    else
      note.id = DreamSync.getRandomSha()
      persistNoteAndSnapshot @db, note, snapshot

persistNoteAndSnapshot = (db, note, snapshot) ->
  new Promise (resolve, reject) ->
    note.id ?= DreamSync.getRandomSha()

    updateTimestamps note, snapshot

    note.snapshotId = snapshot.id

    Promise.all([
      db.notes.update(note)
      db.snapshots.update(snapshot)
    ]).then (-> resolve note), reject

persistDocAndSnapshot = (db, doc, snapshot) ->
  new Promise (resolve, reject) ->
    snapshot.id    ?= DreamSync.getRandomSha()

    updateTimestamps doc, snapshot

    for chapter in doc.chapters
      chapter.id ||= DreamSync.getRandomSha()

    Promise.all([
      db.docs.update(doc)
      db.snapshots.update(snapshot)
    ]).then (-> resolve doc), reject

# Used for both notes and docs
updateTimestamps = (doc, snapshot) ->
  currentTime = new Date().getTime()

  doc.creationTime           ||= currentTime
  doc.lastModifiedTime         = currentTime
  snapshot.creationTime      ||= doc.creationTime
  snapshot.lastModifiedTime    = doc.lastModifiedTime
