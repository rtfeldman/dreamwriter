module Component.LeftSidebar.CurrentDocView (view) where

import Dreamwriter (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)

import List (..)
import LocalChannel (LocalChannel, send)

view : LocalChannel () -> LocalChannel Identifier -> Doc -> Html
view navigateToTitleChannel navigateToChapterIdChannel currentDoc =
  div [key "current-doc-view", id "current-doc-view"] [
    div [id "title", onClick <| send navigateToTitleChannel ()]
      [text currentDoc.title],

    viewOutline navigateToChapterIdChannel currentDoc.chapters
  ]

viewOutline : LocalChannel Identifier -> List Chapter -> Html
viewOutline navigateToChapterIdChannel chapters =
  ul [id "outline"] <| indexedMap (viewChapter navigateToChapterIdChannel) chapters

viewChapter : LocalChannel Identifier -> Int -> Chapter -> Html
viewChapter navigateToChapterIdChannel index chapter = li [
    key ("chapter" ++ (toString index)),
    title chapter.heading,
    onClick <| send navigateToChapterIdChannel chapter.id
  ] [text chapter.heading]