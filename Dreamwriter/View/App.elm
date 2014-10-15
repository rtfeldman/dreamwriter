module Dreamwriter.View.App where

import Dreamwriter.Doc (..)
import Dreamwriter.Model (..)
import Dreamwriter.View.LeftSidebar as LeftSidebar
import Dreamwriter.View.RightSidebar as RightSidebar
import Dreamwriter.View.Editor as Editor

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)

-- TODO remove this once it's in elm-html
key = attr "key"

view : AppState -> Html
view state =
  div [key "#page", id "page"] [
    div [key "#backdrop", class "backdrop"] [
      div [key "#backdrop-tl", class "backdrop-quadrant backdrop-top backdrop-left"] [],
      div [key "#backdrop-bl", class "backdrop-quadrant backdrop-bottom backdrop-left"] [],
      div [key "#backdrop-tr", class "backdrop-quadrant backdrop-top backdrop-right"] [],
      div [key "#backdrop-br", class "backdrop-quadrant backdrop-bottom backdrop-right"] []
    ],

    LeftSidebar.view state,
    Editor.view state,
    RightSidebar.view state
  ]