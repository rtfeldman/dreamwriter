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
        True  ->
          div [key "#left-sidebar-container", id "left-sidebar-container", class "sidebar"] [
            div [key "#left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] [
              span [key "#cancel-open", class "sidebar-header-control",
                onclick actions.handle (\_ -> ToggleOpenMenu False)] [text "cancel"]
            ],

            OpenMenu.view state.docs currentDoc
          ]
        False -> viewCurrentDoc currentDoc

viewCurrentDoc : Doc -> Html
viewCurrentDoc currentDoc =
  let downloadOptions = { filename    = (legalizeFilename currentDoc.title) ++ ".html"
                        , contentType = downloadContentType
                        }
  in
    div [key "#left-sidebar-container", id "left-sidebar-container", class "sidebar"] [
      div [key "#left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] [
        span [key "#new-doc-button", class "sidebar-header-control",
          onclick newDocInput.handle (always ())] [text "new"],
        span [key "#open-doc-button", class "sidebar-header-control",
          onclick actions.handle (\_ -> ToggleOpenMenu True)] [text "open"]
      ],

      div [key "#title", id "title"] [text currentDoc.title],
      div [key "#file-buttons", id "file-buttons"] [
        span [key "#download-button", class "file-button",
          onclick downloadInput.handle (always downloadOptions)] [text "download"],
        span [key "#stats-button", class "file-button"] [text "stats"]
      ],

      Outline.view currentDoc.chapters
    ]