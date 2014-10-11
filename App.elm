module App where

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

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    OpenDoc doc ->
      state -- TODO actually do the open doc stuff


main : Signal Element
main = lift2 scene state Window.dimensions

-- actions from user input
actions : Input.Input Action
actions = Input.input NoOp

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState actions.signal