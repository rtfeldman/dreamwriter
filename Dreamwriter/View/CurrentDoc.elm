module Dreamwriter.View.CurrentDoc (view) where

import Dreamwriter.Doc (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)

import Regex (..)

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

view : Doc -> Html
view currentDoc =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    div [key "current-doc-view", id "current-doc-view"] [
      div [id "title", onclick navigateToTitleInput.handle (always ())]
        [text currentDoc.title],
      div [id "file-buttons"] [
        span [class "file-button flaticon-download14", title "Download",
          onclick downloadInput.handle (always downloadOptions)] [],
        span [class "file-button flaticon-ascendant6", title "Statistics"] [],
        span [class "file-button flaticon-printer70", title "Print",
          onclick printInput.handle (always ())] []
      ],

      viewOutline currentDoc.chapters,

      div [id "add-chapter", class "flaticon-add139"] []
    ]

viewOutline : [Chapter] -> Html
viewOutline chapters =
  ul [id "outline"] <| indexedMap viewChapter chapters

viewChapter : Int -> Chapter -> Html
viewChapter index chapter = li [
    key ("chapter" ++ (show index)),
    onclick navigateToChapterIdInput.handle (always chapter.id)
  ] [text chapter.heading]