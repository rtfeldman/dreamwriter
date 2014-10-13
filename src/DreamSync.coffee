## DreamSync
#
# Handles synchronizing data to/from IndexedDB, remote, etc.

sha1 = require "sha1"

databaseVersion = '1' # Must be an ever-increasing integer for Firefox and a string for Chrome.
desiredStorageQuotaBytes = 1024 * 1024 * 1024 * 1024 # 1TB

module.exports = class DreamSync
  constructor: ->
    storeNames = ['docs', 'snapshots', 'settings']

    vault = new Vault
      name: "dreamwriter"
      version: databaseVersion
      desiredStorageQuotaBytes: desiredStorageQuotaBytes
      stores: storeNames
      storeDefaults: { keyName: 'id' }

    @stores = vault.stores

  putSetting: (id, value, onSuccess, onError) =>
    @stores.settings.put {id, value}, onSuccess, onError

  getSetting: (id, onSuccess, onError) ->
    @stores.settings.get id, ((result) -> onSuccess result?.value), onError

  getCurrentDocId: (onSuccess, onError) ->
    @getSetting "currentDocId", onSuccess, onError

  saveCurrentDocId: (id, onSuccess, onError) ->
    @putSetting "currentDocId", id, onSuccess, onError

  getDoc: (id, onSuccess, onError) ->
    @stores.docs.get id, onSuccess, onError

  getSnapshot: (id, onSuccess, onError) ->
    @stores.snapshots.get id, onSuccess, onError

  saveDocWithSnapshot: (doc, snapshot, onSuccess, onError) ->
    persistDocAndSnapshot = =>
      succeed = => @listeners.emit DreamStore.CHANGE_EVENT
      fail    = -> throw new Error "Error saving doc #{doc?.id} and snapshot #{snapshot?.id}"

      doc.snapshotId ?= snapshot.id ? DreamSync.getRandomSha()
      snapshot.id    ?= doc.snapshotId

      currentDate = new Date()

      doc.creationTimestamp      ||= currentDate
      snapshot.creationTimestamp ||= currentDate
      doc.lastModified      = currentDate
      snapshot.lastModified = currentDate

      onParallelSuccess = -> onSuccess doc, snapshot

      runInParallel [
        (succeed, fail) => @stores.docs.put      doc,      succeed, fail
        (succeed, fail) => @stores.snapshots.put snapshot, succeed, fail
      ], onParallelSuccess, onError

    if doc.id?
      @getDoc doc.id, (existingDoc) =>
        if existingDoc.lastModified.getTime() > doc.lastModified.getTime()
          # TODO handle this by re-rendering etc
          alert "Your document is out of sync! Please refresh."
        else
          persistDocAndSnapshot()
    else
      doc.id = DreamSync.getRandomSha()
      persistDocAndSnapshot()


  @getRandomSha: -> sha1 "#{Math.random()}"[0..16]

runInParallel = (continuations = [], onSuccess = (->), onError = (-> throw new Error "Error executing #{continuations.length} operations in parallel.")) ->
  remaining = continuations.length

  completeWithSuccess = ->
    remaining--
    if remaining < 1
      onSuccess()

  completeWithError = (err) ->
    completeWithError = completeWithSuccess = (->)
    onError err

  continuations.forEach (continuation) ->
    continuation completeWithSuccess, completeWithError
