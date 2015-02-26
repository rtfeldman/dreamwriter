module Dreamwriter.Channel where

import Dreamwriter (..)

import LocalChannel (LocalChannel)
import LocalChannel as LC
import Signal

type alias Locals = {
  newNote             : LocalChannel (),
  searchNotes         : LocalChannel (),
  fullscreen          : LocalChannel FullscreenState,
  syncState           : LocalChannel SyncState,
  execCommand         : LocalChannel String,
  remoteSync          : LocalChannel (),
  print               : LocalChannel (),
  newDoc              : LocalChannel (),
  newChapter          : LocalChannel (),
  openFromFile        : LocalChannel (),
  navigateToTitle     : LocalChannel (),
  navigateToChapterId : LocalChannel Identifier,
  download            : LocalChannel DownloadOptions
}

locals = {
    fullscreen          = LC.create identity fullscreen,
    syncState           = LC.create identity syncState,
    execCommand         = LC.create identity execCommand,
    remoteSync          = LC.create identity remoteSync,
    newNote             = LC.create identity newNote,
    searchNotes         = LC.create identity searchNotes,
    print               = LC.create identity print,
    newDoc              = LC.create identity newDoc,
    newChapter          = LC.create identity newChapter,
    download            = LC.create identity download,
    openFromFile        = LC.create identity openFromFile,
    navigateToTitle     = LC.create identity navigateToTitle,
    navigateToChapterId = LC.create identity navigateToChapterId
  }


download : Signal.Channel DownloadOptions
download = Signal.channel { filename = "", contentType = "" }

newDoc : Signal.Channel ()
newDoc = Signal.channel ()

openFromFile : Signal.Channel ()
openFromFile = Signal.channel ()

navigateToChapterId : Signal.Channel Identifier
navigateToChapterId = Signal.channel ""

navigateToTitle : Signal.Channel ()
navigateToTitle = Signal.channel ()

print : Signal.Channel ()
print = Signal.channel ()

-- TODO make this Signal. String, with the String being the search query
searchNotes : Signal.Channel ()
searchNotes = Signal.channel ()

newNote : Signal.Channel ()
newNote = Signal.channel ()

newChapter : Signal.Channel ()
newChapter = Signal.channel ()

fullscreen : Signal.Channel Bool
fullscreen = Signal.channel False

syncState : Signal.Channel SyncState
syncState = Signal.channel Initializing

execCommand : Signal.Channel String
execCommand = Signal.channel ""

remoteSync : Signal.Channel ()
remoteSync = Signal.channel ()