module Dreamwriter.View.Editor where

import Dreamwriter.Model (..)

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Maybe

view : AppState -> Html
view state =
  -- Even if we have nothing to show, we need to render the iframe so we
  -- can set it up on our first mount. Render it with display:none if need be.
  let containerClass = case state.currentDoc of
    Nothing         -> "hidden"
    Just currentDoc -> ""
  in
    div [id "editor-container", class containerClass] [
      iframe [id "editor-frame", spellcheck True] []
    ]