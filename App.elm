module App where

import Debug

import Dreamwriter (Identifier, newId)
import Dreamwriter.Doc (..)
import Dreamwriter.DocImport as DocImport
import Dreamwriter.Model (..)
import Dreamwriter.View.App (view)

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Html.Optimize.RefEq as Ref
import Maybe
import Window

import Graphics.Input
import Graphics.Input as Input

-- TODO remove this once it's in elm-html
key = attr "key"

-- ACTIONS --

data Action
  = NoOp
  | NewDoc Identifier
  | NewIntroDoc Identifier
  | OpenDoc Doc
  | ChangeEditorContent (Maybe Doc)

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    NewDoc id ->
      step (OpenDoc <| DocImport.newBlankDoc id) state

    NewIntroDoc id ->
      step (OpenDoc <| DocImport.newIntroDoc id) state

    OpenDoc doc ->
      {state | currentDoc <- Just doc}

    ChangeEditorContent maybeDoc ->
      {state | currentDoc <- maybeDoc}

main : Signal Element
main = lift2 scene state Window.dimensions

-- actions from user input
actions : Input.Input Action
actions = Input.input NoOp

userInput : Signal Action
userInput =
  merges
  [ lift ChangeEditorContent getCurrentDoc
  , actions.signal
  ]

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState userInput

port getCurrentDoc : Signal (Maybe Doc)

port setCurrentDoc : Signal (Maybe Doc)
port setCurrentDoc = lift .currentDoc state