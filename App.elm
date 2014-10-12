module App where

import Dreamwriter (Identifier)
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
  | LoadDoc (Identifier, (Maybe Doc))
  | OpenDoc Doc
  | ChangeEditorContent (Maybe Doc)

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    NewDoc id ->
      step (OpenDoc <| DocImport.newBlankDoc id) state

    LoadDoc (id, maybeDoc) ->
      let doc = case maybeDoc of
        Nothing  -> DocImport.newIntroDoc id
        Just doc -> doc
      in step (OpenDoc doc) state

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
  [ lift ChangeEditorContent editDoc
  , lift LoadDoc loadDoc
  , actions.signal
  ]

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState userInput

port editDoc : Signal (Maybe Doc)

-- The database sends a signal that either there's a new doc to be loaded,
-- or that there are no docs to load (indicating the intro doc should be used).
port loadDoc : Signal (Identifier, (Maybe Doc))

port setCurrentDoc : Signal (Maybe Doc)
port setCurrentDoc = lift .currentDoc state