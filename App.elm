module App where

import Debug

import Dreamwriter.Doc (..)
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
  | OpenDoc Doc
  | ChangeTitle String
  | ChangeChapterHeadings [String]

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    OpenDoc doc ->
      state -- TODO actually do the open doc stuff

    ChangeChapterHeadings headings ->
      Debug.log "state"

      {state |
        currentDoc <- Maybe.map (\doc -> updateDoc doc.title headings doc) state.currentDoc
      }

    ChangeTitle title ->
      state
      --{state |
      --  currentDoc <- Maybe.map (\doc -> updateDoc title doc.headings doc) state.currentDoc
      --}

main : Signal Element
main = lift2 scene state Window.dimensions

-- actions from user input
actions : Input.Input Action
actions = Input.input NoOp

userInput : Signal Action
userInput =
  merges
  [ lift ChangeChapterHeadings chapterHeadings
  , lift ChangeTitle docTitle
  , actions.signal
  ]

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState userInput

port chapterHeadings : Signal [String]
port docTitle        : Signal String