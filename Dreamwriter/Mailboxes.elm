module Dreamwriter.Mailboxes (Addresses, Signals, addresses, signals) where

import Dreamwriter exposing (..)

import Signal exposing (Mailbox, Address, mailbox)
import Signal

type alias Addresses = {
  newNote             : Address (),
  openNoteId          : Address Identifier,
  searchNotes         : Address String,
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

addresses : Addresses
addresses = {
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
    navigateToChapterId = navigateToChapterId.address
  }

type alias Signals = {
  newNote             : Signal (),
  openNoteId          : Signal Identifier,
  searchNotes         : Signal String,
  fullscreen          : Signal FullscreenState,
  execCommand         : Signal String,
  remoteSync          : Signal (),
  print               : Signal (),
  newDoc              : Signal (),
  newChapter          : Signal (),
  openFromFile        : Signal (),
  navigateToTitle     : Signal (),
  navigateToChapterId : Signal Identifier,
  download            : Signal DownloadOptions
}

signals : Signals
signals = {
    fullscreen          = fullscreen.signal,
    execCommand         = execCommand.signal,
    remoteSync          = remoteSync.signal,
    newNote             = newNote.signal,
    openNoteId          = openNoteId.signal,
    searchNotes         = searchNotes.signal,
    print               = print.signal,
    newDoc              = newDoc.signal,
    newChapter          = newChapter.signal,
    download            = download.signal,
    openFromFile        = openFromFile.signal,
    navigateToTitle     = navigateToTitle.signal,
    navigateToChapterId = navigateToChapterId.signal
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

searchNotes : Signal.Mailbox String
searchNotes = Signal.mailbox ""

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