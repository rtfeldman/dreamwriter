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
    doc.snapshotId ?= snapshot.id ? DreamSync.getRandomSha()
    snapshot.id    ?= doc.snapshotId

    currentTime = new Date().getTime()

    doc.creationTime           ||= currentTime
    snapshot.creationTime      ||= currentTime
    doc.lastModifiedTime         = currentTime
    snapshot.lastModifiedTime    = currentTime

    Promise.all([
      db.docs.update(doc)
      db.snapshots.update(snapshot)
    ]).then (-> resolve doc), reject
