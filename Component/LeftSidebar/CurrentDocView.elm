module Component.LeftSidebar.CurrentDocView (view) where

import Dreamwriter (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)

import List (..)
import Signal (send)

view : Doc -> Html
view currentDoc =
  div [key "current-doc-view", id "current-doc-view"] [
    div [id "title", onClick <| send navigateToTitleChannel ()]
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
    onClick <| send navigateToChapterIdChannel chapter.id
  ] [text chapter.heading]