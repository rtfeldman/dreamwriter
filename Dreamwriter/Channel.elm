module Dreamwriter.Channel where

import Dreamwriter (..)

import LocalChannel (LocalChannel)
import Signal

type alias Locals = {
  newNote             : LocalChannel (),
  searchNotes         : LocalChannel (),
  fullscreen          : LocalChannel FullscreenState,
  execCommand         : LocalChannel String,
  print               : LocalChannel (),
  newDoc              : LocalChannel (),
  newChapter          : LocalChannel (),
  openFromFile        : LocalChannel (),
  navigateToTitle     : LocalChannel (),
  navigateToChapterId : LocalChannel Identifier,
  download            : LocalChannel DownloadOptions
}

downloadChannel : Signal.Channel DownloadOptions
downloadChannel = Signal.channel { filename = "", contentType = "" }

newDocChannel : Signal.Channel ()
newDocChannel = Signal.channel ()

openFromFileChannel : Signal.Channel ()
openFromFileChannel = Signal.channel ()

navigateToChapterIdChannel : Signal.Channel Identifier
navigateToChapterIdChannel = Signal.channel ""

navigateToTitleChannel : Signal.Channel ()
navigateToTitleChannel = Signal.channel ()

printChannel : Signal.Channel ()
printChannel = Signal.channel ()

-- TODO make this Signal.Channel String, with the String being the search query
searchNotesChannel : Signal.Channel ()
searchNotesChannel = Signal.channel ()

newNoteChannel : Signal.Channel ()
newNoteChannel = Signal.channel ()

newChapterChannel : Signal.Channel ()
newChapterChannel = Signal.channel ()

fullscreenChannel : Signal.Channel Bool
fullscreenChannel = Signal.channel False

execCommandChannel : Signal.Channel String
execCommandChannel = Signal.channel ""