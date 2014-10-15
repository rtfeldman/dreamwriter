module Dreamwriter.View.LeftSidebar (view) where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.Doc (..)
import Dreamwriter.View.Outline as Outline

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
        True  -> viewOpenMenu state.docs currentDoc
        False -> viewCurrentDoc currentDoc

viewOpenDocEntryFor : Doc -> Doc -> Html
viewOpenDocEntryFor currentDoc doc =
  let className = if doc.id == currentDoc.id
    then "open-entry current"
    else "open-entry"
  in
    div [class className,
      onclick actions.handle (\_ -> OpenDocId doc.id)] [text doc.title]

preferDoc : Doc -> Doc -> Doc
preferDoc preferredDoc doc =
  if doc.id == preferredDoc.id
    then preferredDoc
    else doc

viewOpenMenu : [Doc] -> Doc -> Html
viewOpenMenu docs currentDoc =
  -- Prefer the current doc over the docs in the list, since it is refreshed
  -- more often and thus may have more up-to-date information. (Noticeable if
  -- the user is editing the title in real-time with the Open menu showing.)
  let docsPreferringCurrent = map (preferDoc currentDoc) docs

      sortedDocs : [Doc]
      sortedDocs = sortBy (negate << .lastModifiedTime) docsPreferringCurrent

      docEntries : [Html]
      docEntries = map (viewOpenDocEntryFor currentDoc) sortedDocs

      openFileEntry : [Html]
      openFileEntry = [
        input [id "openFileChooser", value "",
          --onchange handleFileChooserChange, 
          (attr "type" "file"), multiple True, accept "text/html"] [],

        div [class "open-entry"
            --, onclick handleShowOpenFile
          ] [
            span [] [text "A "],
            b    [] [text ".html"],
            span [] [text " file from your computer..."]
          ]
      ]
  in
    div [id "left-sidebar-container", class "sidebar", key "left-sidebar-container"] [
      div [key "left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] [
        span [class "sidebar-header-control", key "cancel",
          onclick actions.handle (\_ -> ToggleOpenMenu False)] [text "cancel"]
      ],
      div [id "open"] (openFileEntry ++ docEntries)
    ]

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