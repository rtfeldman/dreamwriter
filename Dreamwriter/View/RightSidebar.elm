module Dreamwriter.View.RightSidebar where

import Dreamwriter.Doc (..)
import Dreamwriter.Model (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)
import Maybe

view : Doc -> AppState -> Html
view currentDoc state =
  div [id "right-sidebar-container", class "sidebar"] [
    div [id "right-sidebar-header", class "sidebar-header"] [
      input [id "notes-search-text", placeholder "Search Notes"] [],
      span [id "notes-search-button", class "sidebar-header-control flaticon-ribbon"] []
    ],
    div [id "right-sidebar-body"] [
      div [id "notes"] []
    ]
  ]