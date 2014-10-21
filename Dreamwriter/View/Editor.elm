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
      div [id "editor-header"] [
        div [class "toolbar-section toolbar-button flaticon-zoom19"] [],
        div [class "toolbar-section toolbar-button"] [
          span [class "font-control toolbar-font-button", id "toggle-bold"] [text "B"],
          span [class "font-control toolbar-font-button", id "toggle-italics"] [text "I"],
          span [class "font-control toolbar-font-button", id "toggle-strikethrough"] [text "\xA0S\xA0"]
        ],
        div [class "toolbar-section toolbar-button flaticon-expand"] []
      ],
      div [id "document-page"] <| [
        h1  [id "edit-title",        class "editable", contenteditable True, spellcheck True] [text currentDoc.title],
        div [id "edit-description",  class "editable", contenteditable True, spellcheck True] []
      ] ++ map viewChapter currentDoc.chapters,
      div [id "editor-footer"] [
        div [id "doc-word-count"] [text "23,124 words saved"],
        div [id "dropbox-sync"] [text "enable Dropbox syncing"]
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