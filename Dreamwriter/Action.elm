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

downloadInput : Signal.Channel DownloadOptions
downloadInput = Signal.channel { filename = "", contentType = "" }

newDocInput : Signal.Channel ()
newDocInput = Signal.channel ()

openFromFileInput : Signal.Channel ()
openFromFileInput = Signal.channel ()

navigateToChapterIdInput : Signal.Channel Identifier
navigateToChapterIdInput = Signal.channel ""

navigateToTitleInput : Signal.Channel ()
navigateToTitleInput = Signal.channel ()

printInput : Signal.Channel ()
printInput = Signal.channel ()

-- TODO make this Signal.Channel String, with the String being the search query
searchNotesInput : Signal.Channel ()
searchNotesInput = Signal.channel ()

newNoteInput : Signal.Channel ()
newNoteInput = Signal.channel ()

newChapterInput : Signal.Channel ()
newChapterInput = Signal.channel ()

fullscreenInput : Signal.Channel Bool
fullscreenInput = Signal.channel False

execCommandInput : Signal.Channel String
execCommandInput = Signal.channel ""