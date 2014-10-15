module Dreamwriter.View.CurrentDoc (view) where

import Dreamwriter.Doc (..)
import Dreamwriter.Action (..)
import Dreamwriter.Model (..)

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

view : Doc -> Html
view currentDoc =
  let downloadOptions = { filename    = (legalizeFilename currentDoc.title) ++ ".html"
                        , contentType = downloadContentType
                        }
  in
    div [id "current-doc", key "current-doc"] [
      div [id "title", key "title"] [text currentDoc.title],
      div [id "file-buttons", key "file-buttons"] [
        span [class "file-button", key "download", onclick downloadInput.handle (always downloadOptions)] [text "download"],
        span [class "file-button", key "stats"] [text "stats"]
      ],

      viewOutline currentDoc.chapters
    ]

viewOutline : [Chapter] -> Html
viewOutline chapters =
  ul [id "outline", key "outline"] <| indexedMap viewChapter chapters

viewChapter : Int -> Chapter -> Html
viewChapter index chapter = li [key ("chapter" ++ (show index))] [text chapter.heading]
