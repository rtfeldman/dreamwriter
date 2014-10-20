module Dreamwriter.View.RightSidebar where

import Dreamwriter.Doc (..)
import Dreamwriter.Model (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)
import Maybe

view : Doc -> AppState -> Html
view currentDoc state =
  div [id "right-sidebar-container", class "sidebar"] []