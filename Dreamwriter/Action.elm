module Dreamwriter.Action where

import Dreamwriter (..)
import Dreamwriter.Doc (..)

import Graphics.Input
import Graphics.Input as Input

data Action
  = NoOp
  | LoadAsCurrentDoc Doc
  | OpenDocId Identifier
  | ListDocs [Doc]
  | ToggleOpenMenu Bool

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