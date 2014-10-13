module App where

import Dreamwriter (Identifier)
import Dreamwriter.Action (..)
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

-- TODO remove this once it's in elm-html
key = attr "key"

-- ACTIONS --

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    NewDoc ->
      {state | pendingHtml <- Just DocImport.blankDocHtml}

    OpenDoc id ->
      {state | currentDocId <- Just id
             , showOpenMenu <- False}

    LoadDoc (id, maybeDoc) ->
      case maybeDoc of
        -- When there is no doc available to load, load the intro doc.
        Nothing ->
          {state | pendingHtml <- Just DocImport.introDocHtml}

        -- When a doc is provided, load it and clear out pending.
        Just doc ->
          {state | currentDoc   <- Just doc
                 , currentDocId <- Just id
                 , pendingHtml  <- Nothing
          }

    ChangeEditorContent maybeDoc ->
      {state | currentDoc <- maybeDoc}

main : Signal Element
main = lift2 scene state Window.dimensions

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

port setCurrentDocId : Signal (Maybe Identifier)
port setCurrentDocId = lift .currentDocId state

port setPendingHtml : Signal (Maybe String)
port setPendingHtml = lift .pendingHtml state