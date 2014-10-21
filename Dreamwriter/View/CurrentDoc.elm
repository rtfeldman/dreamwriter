module Dreamwriter.View.CurrentDoc (view) where

import Dreamwriter.Doc (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)

view : Doc -> Html
view currentDoc =
  div [key "current-doc-view", id "current-doc-view"] [
    div [id "title", onclick navigateToTitleInput.handle (always ())]
      [text currentDoc.title],

    viewOutline currentDoc.chapters,

    div [id "add-chapter", class "flaticon-add139"] []
  ]

viewOutline : [Chapter] -> Html
viewOutline chapters =
  ul [id "outline"] <| indexedMap viewChapter chapters

viewChapter : Int -> Chapter -> Html
viewChapter index chapter = li [
    key ("chapter" ++ (show index)),
    title chapter.heading,
    onclick navigateToChapterIdInput.handle (always chapter.id)
  ] [text chapter.heading]