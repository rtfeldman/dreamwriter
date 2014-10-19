module Dreamwriter.View.RightSidebar where

import Dreamwriter.Model (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)
import Maybe

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing ->
      span [] []
    Just currentDoc ->
      div [id "right-sidebar-container", class "sidebar"] []