module Dreamwriter.View.RightSidebar where

import Dreamwriter.Model (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Maybe

view : Doc -> AppState -> Html
view currentDoc state =
  let {sidebarBody, sidebarFooter} = case state.currentNote of
    Nothing ->
      { sidebarBody   = lazy viewNoteListings state.notes
      , sidebarFooter = span [] []
      }
    Just currentNote ->
      { sidebarBody   = lazy viewCurrentNoteBody   currentNote
      , sidebarFooter = lazy viewCurrentNoteFooter currentNote
      }
  in
    div [id "right-sidebar-container", class "sidebar"] [
      div [id "right-sidebar-header", class "sidebar-header"] [
        input [id "notes-search-text", class "sidebar-header-control", placeholder "search notes",
          onkeyup searchNotesInput.handle (always ())] [],
        span [id "notes-search-button", class "sidebar-header-control flaticon-pencil90",
          onClick newNoteInput.handle (always ())] []
      ],
      div [id "right-sidebar-body", class "sidebar-body"] [
        sidebarBody
      ],
      sidebarFooter
    ]

viewNoteListings notes =
  div [id "note-listings"] <| map viewNoteListing notes

viewNoteListing : Note -> Html
viewNoteListing note =
  div [key ("note-" ++ note.id), class "note-listing",
    onClick actions.handle (\_ -> SetCurrentNote (Just note))] [
      div [class "flaticon-document127 note-listing-icon"] [],
      div [class "note-listing-title"] [text note.title]
    ]

viewCurrentNoteBody : Note -> Html
viewCurrentNoteBody note =
  div [key ("current-note-" ++ note.id), id "current-note"] [
    div [id "current-note-title-container"] [
      div [id "current-note-title"] [text note.title],
      div [id "close-current-note", class "flaticon-close15",
        title "Close Note",
        onClick actions.handle (\_ -> SetCurrentNote Nothing)] []
    ],
    div [id "current-note-body"] []
  ]

viewCurrentNoteFooter : Note -> Html
viewCurrentNoteFooter note =
  div [id "current-note-controls", class "sidebar-footer"] [
    span [id "download-current-note",
      title "Download Note",
      class "flaticon-cloud134 current-note-control"] [],
    span [id "print-current-note",
      title "Print Note",
      class "flaticon-printer70 current-note-control"] [],
    span [id "current-note-settings",
      title "Note Settings",
      class "flaticon-gear33 current-note-control"] [],
    span [id "delete-current-note",
      title "Delete Note",
      class "flaticon-closed18 current-note-control"] []
  ]