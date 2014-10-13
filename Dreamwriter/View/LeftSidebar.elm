module Dreamwriter.View.LeftSidebar where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.View.Outline as Outline

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
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
      div [id "left-sidebar-container", class "sidebar", key "left-sidebar-container"] [
        div [key "left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] [
          span [class "sidebar-header-control", key "new", onclick newDocInput.handle (always ())] [text "new"],
          span [class "sidebar-header-control", key "open"] [text "open"]
          --span [class "sidebar-header-control", key "open", onClick (getOpenMenuClickHandler true)] [text "open"]
        ],

        div [id "title", key "title"] [text currentDoc.title],
        div [id "file-buttons", key "file-buttons"] [
          span [class "file-button", key "download"] [text "download"],
          --span [class "file-button", key "download", onClick @handleDownload] ["download"]
          span [class "file-button", key "stats"] [text "stats"]
        ],

        Outline.view currentDoc.chapters
      ]