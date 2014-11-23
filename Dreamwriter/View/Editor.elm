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

view : Doc -> AppState -> Html
view currentDoc state =
  RefEq.lazy2 viewEditor currentDoc state.fullscreen

viewEditor currentDoc fullscreen =
  div [id "editor-container"] [
    div [id "editor-frame"] [
      div [id "editor-header"] [
        div [class "toolbar-section toolbar-button flaticon-zoom19"] [],
        div [class "toolbar-section"] [
          viewFontControl "toggle-bold" "B" "bold",
          viewFontControl "toggle-italics" "I" "italic",
          viewFontControl "toggle-strikethrough" "\xA0S\xA0" "strikethrough"
        ],
        RefEq.lazy viewFullscreenButton fullscreen
      ],

      div [id "document-page"] <| [
        h1  [id "edit-title"      ] [],
        div [id "edit-description"] []
      ] ++ concatMap (lazyViewChapter << .id) currentDoc.chapters,

      div [id "editor-footer"] [
        div [id "doc-word-count"] [text <| (pluralize "word" currentDoc.words) ++ " saved"],
        div [id "dropbox-sync"] [
          input [id "toggle-dropbox-sync", attr "type" "checkbox"] [],
          label [for "toggle-dropbox-sync"] [
            text " sync to Dropbox"
          ]
        ]
      ]
    ]
  ]

withCommas : Int -> String
withCommas num =
  if num >= 1000
    then
      let extraDigits = floor (num / 1000)
          prefix      = withCommas extraDigits
      in
        -- TODO change this to the equivalent of num[num.length - 3..num.length]
        -- because otherwise we get badness around zeroes, e.g. 19,034 -> 19,34
        prefix ++ "," ++ (show <| num - (extraDigits * 1000))
    else
      show num

pluralize : String -> Int -> String
pluralize noun quantity =
  if quantity == 1
    then "1 " ++ noun
    else (withCommas quantity) ++ " " ++ noun ++ "s"

viewFullscreenButton fullscreen =
  let {fullscreenClass, targetMode, fullscreenTitle} = case fullscreen of
    True ->
      { fullscreenClass = "flaticon-collapsing"
      , targetMode      = False
      , fullscreenTitle = "Leave Fullscreen Mode"
      }
    False ->
      { fullscreenClass = "flaticon-expand"
      , targetMode      = True
      , fullscreenTitle = "Enter Fullscreen Mode"
      }
  in
    div [class ("toolbar-section toolbar-button " ++ fullscreenClass),
      title fullscreenTitle,
      onclick fullscreenInput.handle (always targetMode)
    ] []

lazyViewChapter : Identifier -> [Html]
lazyViewChapter chapterId = [
    RefEq.lazy viewChapterHeading chapterId,
    RefEq.lazy viewChapterBody    chapterId
  ]

viewChapterBody : Identifier -> Html
viewChapterBody chapterId =
  div [key ("chapter-body-" ++ chapterId),
    id ("edit-chapter-body-" ++ chapterId),
    class "chapter-body"] []

viewChapterHeading : Identifier -> Html
viewChapterHeading chapterId =
  h2 [key ("chapter-heading-" ++ chapterId),
    id ("edit-chapter-heading-" ++ chapterId),
    class "chapter-heading"] []

viewFontControl : String -> String -> String -> Html
viewFontControl idAttr label command =
  span [class "font-control toolbar-button toolbar-font-button", id idAttr,
    (attr "unselectable" "on"),
    onclick execCommandInput.handle (always command)] [text label]