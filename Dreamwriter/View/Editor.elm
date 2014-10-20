module Dreamwriter.View.Editor where

import Dreamwriter.Model (..)

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Maybe

-- TODO remove this once it's fixed in elm-html
contenteditable = toggle "contentEditable" 

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing -> span [] []
    Just currentDoc -> 
      div [id "editor-container"] [
        div [id "editor-frame"] [
          div [class "document-page"] [
            section [id "preface"] [
              header [id "edit-preface-header", contenteditable True, spellcheck True] [text currentDoc.title],
              section [id "edit-preface", contenteditable True, spellcheck True] []
            ]
          ]
        ]
      ]