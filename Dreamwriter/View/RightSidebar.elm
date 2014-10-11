module Dreamwriter.View.RightSidebar where

import Dreamwriter.Model (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)
import Maybe

-- TODO remove this once it's in elm-html
key = attr "key"

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing ->
      span [] []
    Just currentDoc ->
      div [id "right-sidebar-container", class "sidebar", key "right-sidebar-container"] []