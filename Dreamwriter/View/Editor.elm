module Dreamwriter.View.Editor where

import Dreamwriter.Model (..)
import Dreamwriter.Action (..)
import Dreamwriter (..)

import String
import Html (..)
import Html.Attributes (..)
import Html.Optimize.RefEq as RefEq
import Html.Events (..)
import Html.Tags (..)
import Maybe

-- TODO remove this once it's fixed in elm-html
contenteditable = toggle "contentEditable" 

view : Doc -> AppState -> Html
view currentDoc state =
  RefEq.lazy2 viewEditor currentDoc state.fullscreen

viewEditor currentDoc fullscreen =
  div [id "editor-container"] [
    div [id "editor-frame"] [
      div [id "editor-header"] [
        div [class "toolbar-section toolbar-button flaticon-zoom19"] [],
        div [class "toolbar-section"] [
          span [class "font-control toolbar-button toolbar-font-button", id "toggle-bold"] [text "B"],
          span [class "font-control toolbar-button toolbar-font-button", id "toggle-italics"] [text "I"],
          span [class "font-control toolbar-button toolbar-font-button", id "toggle-strikethrough"] [text "\xA0S\xA0"]
        ],
        RefEq.lazy viewFullscreenButton fullscreen
      ],

      div [id "document-page"] <| [
        h1  [class "editable", id "edit-title",       contenteditable True, spellcheck True] [],
        div [class "editable", id "edit-description", contenteditable True, spellcheck True] []
      ] ++ map (lazyViewChapter << .id) currentDoc.chapters,

      div [id "editor-footer"] [
        div [id "doc-word-count"] [text "23,124 words saved"],
        div [id "dropbox-sync"] [text "enable Dropbox syncing"]
      ]
    ]
  ]

viewFullscreenButton fullscreen =
  let {fullscreenClass, targetMode} = case fullscreen of
    True ->
      { fullscreenClass = "flaticon-collapsing"
      , targetMode      = False
      }
    False ->
      { fullscreenClass = "flaticon-expand"
      , targetMode      = True
      }
  in
    div [class ("toolbar-section toolbar-button " ++ fullscreenClass),
      onclick fullscreenInput.handle (always targetMode)
    ] []

lazyViewChapter : Identifier -> Html
lazyViewChapter chapterId = RefEq.lazy viewChapter chapterId

viewChapter : Identifier -> Html
viewChapter chapterId =
  div [key ("chapter " ++ chapterId)] [
    h2  [contenteditable True, spellcheck True,
      id ("edit-chapter-heading-" ++ chapterId),
      class "editable chapter-heading"] [],
    div [contenteditable True, spellcheck True,
      id ("edit-chapter-body-" ++ chapterId),    
      class "editable chapter-body"] []
  ]