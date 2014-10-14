## DreamSync
#
# Handles synchronizing data to/from IndexedDB, remote, etc.

dbjs = require "db.js"
sha1 = require "sha1"

databaseVersion = '1' # Must be an ever-increasing integer for Firefox and a string for Chrome.

defaultKeySettings = {keyPath: "id", autoIncrement: false}
defaultConnectionOptions =
  server: "dreamwriter"
  version: databaseVersion
  schema:
    settings:
      key: defaultKeySettings
    docs:
      key: defaultKeySettings
    snapshots:
      key: defaultKeySettings

module.exports = class DreamSync
  constructor: (connection) ->
    @db = connection

  @connect: (options = defaultConnectionOptions) ->
    new Promise (resolve, reject) ->
      dbjs.open(options).then ((conn) -> resolve new DreamSync conn), reject

  @getRandomSha: -> sha1 "#{Math.random()}"[0..16]

  getCurrentDocId:       => @getSetting  "currentDocId"
  saveCurrentDocId: (id) => @saveSetting "currentDocId", id

  saveSetting: (id, value) => @db.settings.update {id, value}
  getSetting:  (id) =>
    new Promise (resolve, reject) =>
      @db.settings.get(id).then ((result) -> resolve result?.value), reject

  getDoc:      (id) => @db.docs.get      id
  getSnapshot: (id) => @db.snapshots.get id

  saveDocWithSnapshot: (doc, snapshot) ->
    if doc.id?
      new Promise (resolve, reject) =>
        @getDoc(doc.id).then (existingDoc) =>
          if existingDoc.lastModified.getTime() > doc.lastModified.getTime()
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

    currentDate = new Date()

    doc.creationTimestamp      ||= currentDate
    snapshot.creationTimestamp ||= currentDate
    doc.lastModified      = currentDate
    snapshot.lastModified = currentDate

    runInParallel([
      db.docs.update(doc)
      db.snapshots.update(snapshot)
    ]).then (-> resolve {doc, snapshot}), reject

runInParallel = (promises) ->
  new Promise (resolve, reject) ->
    remaining = promises.length

    completeWithSuccess = ->
      remaining--
      if remaining < 1
        resolve()

    completeWithError = (err) ->
      completeWithError = completeWithSuccess = (->)
      reject err

    promises.forEach (promise) ->
      promise.then completeWithSuccess, completeWithError
