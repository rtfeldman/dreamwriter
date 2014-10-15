module Dreamwriter.View.CurrentDoc (view) where

import Dreamwriter.Doc (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)

import Regex (..)

-- TODO remove this once it's in elm-html
key = attr "key"

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

-- TODO refactor this to return Html instead of [Html] once vdom bug is fixed...
view : Doc -> Html
view currentDoc =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    div [key "#current-doc-view", id "current-doc-view"] [
      div [key "#title", id "title"] [text currentDoc.title],
      div [key "#file-buttons", id "file-buttons"] [
        span [key "#download-button", class "file-button",
          onclick downloadInput.handle (always downloadOptions)] [text "download"],
        span [key "#stats-button", class "file-button"] [text "stats"]
      ],

      viewOutline currentDoc.chapters
    ]

viewOutline : [Chapter] -> Html
viewOutline chapters =
  ul [id "outline", key "outline"] <| indexedMap viewChapter chapters

viewChapter : Int -> Chapter -> Html
viewChapter index chapter = li [key ("chapter" ++ (show index))] [text chapter.heading]