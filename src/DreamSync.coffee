## DreamSync
#
# Handles synchronizing data to/from IndexedDB, remote, etc.

dbjs       = require "db.js"
sha1       = require "sha1"
dbOptions  = require "./idb-options.json"
countWords = require "./WordCount.coffee"

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
