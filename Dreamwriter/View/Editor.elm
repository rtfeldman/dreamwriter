module Dreamwriter.View.Editor where

import Dreamwriter.Doc (..)
import Dreamwriter.Model (..)

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Maybe

-- TODO remove this once it's fixed in elm-html
contenteditable = toggle "contentEditable" 


view : Doc -> AppState -> Html
view currentDoc state =
  div [id "editor-container"] [
    div [id "editor-frame"] [
      div [id "document-page"] [
        h1  [id "edit-title",        contenteditable True, spellcheck True] [text currentDoc.title],
        div [id "edit-description",  contenteditable True, spellcheck True] [],
        div [id "chapters"] <| map viewChapter currentDoc.chapters
      ]
    ]
  ]

viewChapter : Chapter -> Html
viewChapter chapter =
  div [key ("chapter " ++ chapter.id)] [
    h2  [contenteditable True, spellcheck True,
      id ("edit-chapter-heading-" ++ chapter.id),
      class "editable chapter-heading"] [text chapter.heading],
    div [contenteditable True, spellcheck True,
      id ("edit-chapter-body-" ++ chapter.id),    
      class "editable chapter-body"] []
  ]