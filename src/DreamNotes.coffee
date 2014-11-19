## DreamNotes
#
# Handles managing notes, including full text search capabilities.

lunr = require "lunr"

module.exports = class DreamNotes
  # If an optional serializedIndex is provided, loads that as the current
  # index. Otherwise, creates a new one from scratch.
  constructor: (@sync, serializedIndex) ->
    @index = if serializedIndex?
      lunr.Index.load serializedIndex
    else
      lunr ->
        @ref   "id"
        @field "title", boost: 10
        @field "body"

  # Persist the note in the database and update the index accordingly.
  save: (note, body) =>
    new Promise (resolve, reject) =>
      onPersistSuccess = (savedNote) =>
        indexableNote = {id: savedNote.id, title: savedNote.title, body}

        if note.id?
          @index.update indexableNote
        else
          @index.add    indexableNote

        @saveIndex().then (-> resolve indexableNote), reject

      # Always persist the note first! If something goes wrong, prioritize
      # saving what the user wrote.
      @sync.saveNoteWithSnapshot(note, body).then onPersistSuccess, reject

  # Returns a promise which resolves to the list of notes that match
  # the given query, including id and title (but not body).
  search: (query) =>
    ids = @index.search(query).map ({ref}) -> ref

    @sync.getNotes ids

  # Persist the serialized index to facilitate fast loading later.
  saveIndex: =>
    @sync.saveNotesIndex @index.toJSON()