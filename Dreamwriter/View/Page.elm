module Dreamwriter.View.Page where

import Dreamwriter.Model (..)
import Dreamwriter.View.LeftSidebar as LeftSidebar
import Dreamwriter.View.RightSidebar as RightSidebar
import Dreamwriter.View.Editor as Editor

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)

view : AppState -> Html
view state =
  div [id "page"] <|
    case state.currentDoc of
      Nothing -> []
      Just currentDoc ->
        [
          LeftSidebar.view  currentDoc state,
          Editor.view       currentDoc state,
          RightSidebar.view currentDoc state
        ]