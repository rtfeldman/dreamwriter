module Dreamwriter.View.RightSidebar where

import Dreamwriter.Model (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)
import Html.Events (..)
import Maybe

-- TODO remove this once it's fixed in elm-html
contenteditable = toggle "contentEditable" 

view : Doc -> AppState -> Html
view currentDoc state =
  let sidebarBody = case state.currentNote of
    Nothing ->
      div [id "note-listings"] <| map viewNoteListing state.notes
    Just currentNote ->
      viewCurrentNote currentNote
  in
    div [id "right-sidebar-container", class "sidebar"] [
      div [id "right-sidebar-header", class "sidebar-header"] [
        input [id "notes-search-text", class "sidebar-header-control", placeholder "search notes",
          onkeyup searchNotesInput.handle (always ())] [],
        span [id "notes-search-button", class "sidebar-header-control flaticon-pencil90",
          onclick newNoteInput.handle (always ())] []
      ],
      div [id "right-sidebar-body"] [
        sidebarBody
      ]
    ]

viewNoteListing : Note -> Html
viewNoteListing note =
  div [key ("note-" ++ note.id), class "note-listing",
    onclick actions.handle (\_ -> SetCurrentNote (Just note))] [
      div [class "flaticon-document127 note-listing-icon"] [],
      div [class "note-listing-title"] [text note.title]
    ]

viewCurrentNote : Note -> Html
viewCurrentNote note =
  div [key ("current-note-" ++ note.id), id "current-note"] [
    div [id "current-note-title-container"] [
      div [id "current-note-title"] [text note.title],
      div [id "close-current-note", class "flaticon-close15",
        title "Close Note",
        onclick actions.handle (\_ -> SetCurrentNote Nothing)] []
    ],
    div [id "current-note-controls"] [
      span [id "download-current-note",
        title "Download Note",
        class "flaticon-cloud134 current-note-control"] [],
      span [id "print-current-note",
        title "Print Note",
        class "flaticon-printer70 current-note-control"] [],
      span [id "current-note-settings",
        title "Note Settings",
        class "flaticon-machine2 current-note-control"] [],
      span [id "delete-current-note",
        title "Delete Note",
        class "flaticon-closed18 current-note-control"] []
    ],
    div [id "current-note-body", contenteditable True] [text "TODO: Write a note here!"]
  ]