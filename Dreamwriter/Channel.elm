module Dreamwriter.Channel where

import Dreamwriter exposing (..)

import Signal exposing (Mailbox, Address, mailbox)
import Signal

type alias Addresses = {
  newNote             : Address (),
  openNoteId          : Address Identifier,
  searchNotes         : Address (),
  fullscreen          : Address FullscreenState,
  execCommand         : Address String,
  remoteSync          : Address (),
  print               : Address (),
  newDoc              : Address (),
  newChapter          : Address (),
  openFromFile        : Address (),
  navigateToTitle     : Address (),
  navigateToChapterId : Address Identifier,
  download            : Address DownloadOptions
}

locals = {
    fullscreen          = fullscreen.address,
    execCommand         = execCommand.address,
    remoteSync          = remoteSync.address,
    newNote             = newNote.address,
    openNoteId          = openNoteId.address,
    searchNotes         = searchNotes.address,
    print               = print.address,
    newDoc              = newDoc.address,
    newChapter          = newChapter.address,
    download            = download.address,
    openFromFile        = openFromFile.address,
    navigateToTitle     = navigateToTitle.address,
    navigateToChapterId = navigateToChapterId
  }

download : Signal.Mailbox DownloadOptions
download = Signal.mailbox { filename = "", contentType = "" }

newDoc : Signal.Mailbox ()
newDoc = Signal.mailbox ()

openFromFile : Signal.Mailbox ()
openFromFile = Signal.mailbox ()

navigateToChapterId : Signal.Mailbox Identifier
navigateToChapterId = Signal.mailbox ""

navigateToTitle : Signal.Mailbox ()
navigateToTitle = Signal.mailbox ()

print : Signal.Mailbox ()
print = Signal.mailbox ()

-- TODO make this Signal. String, with the String being the search query
searchNotes : Signal.Mailbox ()
searchNotes = Signal.mailbox ()

newNote : Signal.Mailbox ()
newNote = Signal.mailbox ()

openNoteId : Signal.Mailbox Identifier
openNoteId = Signal.mailbox ""

newChapter : Signal.Mailbox ()
newChapter = Signal.mailbox ()

fullscreen : Signal.Mailbox Bool
fullscreen = Signal.mailbox False

execCommand : Signal.Mailbox String
execCommand = Signal.mailbox ""

remoteSync : Signal.Mailbox ()
remoteSync = Signal.mailbox ()