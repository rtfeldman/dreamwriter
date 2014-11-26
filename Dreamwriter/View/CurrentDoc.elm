module Dreamwriter.View.CurrentDoc (view) where

import Dreamwriter.Model (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)

import List (..)
import Signal (send)

view : Doc -> Html
view currentDoc =
  div [key "current-doc-view", id "current-doc-view"] [
    div [id "title", onClick <| send navigateToTitleInput (always ())]
      [text currentDoc.title],

    viewOutline currentDoc.chapters
  ]

viewOutline : List Chapter -> Html
viewOutline chapters =
  ul [id "outline"] <| indexedMap viewChapter chapters

viewChapter : Int -> Chapter -> Html
viewChapter index chapter = li [
    key ("chapter" ++ (toString index)),
    title chapter.heading,
    onClick <| send navigateToChapterIdInput (always chapter.id)
  ] [text chapter.heading]