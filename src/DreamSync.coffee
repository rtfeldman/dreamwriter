## DreamSync
#
# Handles synchronizing data to/from IndexedDB, remote, etc.

dbjs      = require "db.js"
sha1      = require "sha1"
dbOptions = require "./idb-options.json"

module.exports = class DreamSync
  constructor: (@db) ->

  @connect: ->
    new Promise (resolve, reject) ->
      dbjs.open(dbOptions).then ((conn) -> resolve new DreamSync conn), reject

  @getRandomSha: -> sha1 "#{Math.random()}"[0..16]

  getCurrentDocId:       => @getSetting  "currentDocId"
  saveCurrentDocId: (id) => @saveSetting "currentDocId", id

  saveSetting: (id, value) => @db.settings.update {id, value}
  getSetting:  (id) =>
    new Promise (resolve, reject) =>
      @db.settings.get(id).then ((result) -> resolve result?.value), reject

  listDocs: => @db.docs.query().all().execute()

  getDoc:      (id) => @db.docs.get      id
  getSnapshot: (id) => @db.snapshots.get id

  getCurrentDoc: =>
    new Promise (resolve, reject) =>
      @getCurrentDocId().then (id) =>
        @getDoc(id).then resolve, reject

  saveDoc:      (doc)      => @db.docs.update      doc
  saveSnapshot: (snapshot) => @db.snapshots.update snapshot

  addChapter: (doc, heading, html) =>
    snapshot = {id: DreamSync.getRandomSha(), html}

    currentTime = new Date().getTime()

    chapter = {
      id:               DreamSync.getRandomSha()
      heading:          heading
      lastModifiedTime: currentTime
      creationTime:     currentTime
      snapshotId:       snapshot.id
      words:            0 # TODO count words!
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

persistDocAndSnapshot = (db, doc, snapshot) ->
  new Promise (resolve, reject) ->
    snapshot.id    ?= DreamSync.getRandomSha()

    currentTime = new Date().getTime()

    doc.creationTime           ||= currentTime
    doc.lastModifiedTime         = currentTime
    snapshot.creationTime      ||= doc.creationTime
    snapshot.lastModifiedTime    = doc.lastModifiedTime

    for chapter in doc.chapters
      chapter.id ||= DreamSync.getRandomSha()

    Promise.all([
      db.docs.update(doc)
      db.snapshots.update(snapshot)
    ]).then (-> resolve doc), reject
