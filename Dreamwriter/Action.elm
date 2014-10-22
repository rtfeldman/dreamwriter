module Dreamwriter.Action where

import Dreamwriter (..)
import Dreamwriter.Model (..)

import Graphics.Input
import Graphics.Input as Input

data Action
  = NoOp
  | LoadAsCurrentDoc Doc
  | OpenDocId Identifier
  | ListDocs [Doc]
  | ListNotes [Note]
  | SetCurrentNote (Maybe Note)
  | SetLeftSidebarView LeftSidebarView

-- actions from user input
actions : Input.Input Action
actions = Input.input NoOp

type DownloadOptions =
  { filename    : String
  , contentType : String
  }

downloadInput : Input.Input DownloadOptions
downloadInput = Input.input { filename = "", contentType = "" }

newDocInput : Input.Input ()
newDocInput = Input.input ()

openFromFileInput : Input.Input ()
openFromFileInput = Input.input ()

navigateToChapterIdInput : Input.Input Identifier
navigateToChapterIdInput = Input.input ""

navigateToTitleInput : Input.Input ()
navigateToTitleInput = Input.input ()

printInput : Input.Input ()
printInput = Input.input ()

-- TODO make this Input.Input String, with the String being the search query
searchNotesInput : Input.Input ()
searchNotesInput = Input.input ()

newNoteInput : Input.Input ()
newNoteInput = Input.input ()