module Dreamwriter.View.LeftSidebar (view) where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.Doc (..)
import Dreamwriter.View.Outline as Outline
import Dreamwriter.View.OpenMenu as OpenMenu

import Regex (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Maybe

-- TODO remove this once it's in elm-html
key = attr "key"

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing ->
      span [] []
    Just currentDoc ->
      case state.showOpenMenu of
        True  -> OpenMenu.view state.docs currentDoc
        False -> viewCurrentDoc currentDoc

viewCurrentDoc : Doc -> Html
viewCurrentDoc currentDoc =
  let downloadOptions = { filename    = (legalizeFilename currentDoc.title) ++ ".html"
                        , contentType = downloadContentType
                        }
  in
    div [id "left-sidebar-container", class "sidebar", key "left-sidebar-container"] [
      div [key "left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] [
        span [class "sidebar-header-control", key "new",
          onclick newDocInput.handle (always ())] [text "new"],
        span [class "sidebar-header-control", key "open",
          onclick actions.handle (\_ -> ToggleOpenMenu True)] [text "open"]
      ],

      div [id "title", key "title"] [text currentDoc.title],
      div [id "file-buttons", key "file-buttons"] [
        span [class "file-button", key "download", onclick downloadInput.handle (always downloadOptions)] [text "download"],
        span [class "file-button", key "stats"] [text "stats"]
      ],

      Outline.view currentDoc.chapters
      ]