module Dreamwriter.Action where

import Dreamwriter (..)
import Dreamwriter.Model (..)

import Signal

type Action
  = NoOp
  | LoadAsCurrentDoc Doc
  | OpenDocId Identifier
  | ListDocs (List Doc)
  | ListNotes (List Note)
  | SetCurrentNote (Maybe Note)
  | SetLeftSidebarView LeftSidebarView
  | SetChapters (List Chapter)
  | UpdateChapter Chapter
  | SetTitle (String, Int)
  | SetDescription (String, Int)
  | SetFullscreen FullscreenState
  | PutSnapshot Snapshot

-- actions from user input
actions : Signal.Channel Action
actions = Signal.channel NoOp

type alias DownloadOptions =
  { filename    : String
  , contentType : String
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