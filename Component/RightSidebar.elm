module Component.RightSidebar where

import Dreamwriter (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Maybe
import LocalChannel (send, LocalChannel)
import List (..)

type alias Channels a = { a |
  newNote     : LocalChannel (),
  searchNotes : LocalChannel (),
  update      : LocalChannel Update
}

type alias Model = {
  currentNote : Maybe Note,
  notes       : List Note
}

initialModel : Model
initialModel = {
    currentNote = Nothing,
    notes       = []
  }

type Update
  = NoChange
  | SetCurrentNote (Maybe Note)

transition : Update -> Model -> Model
transition update model =
  case update of
    NoChange -> model
    SetCurrentNote note -> { model | currentNote <- note }

view : Channels a -> Model -> Html
view channels model =
  let {sidebarBody, sidebarFooter} = case model.currentNote of
    Nothing ->
      { sidebarBody   = lazy2 viewNoteListings channels.update model.notes
      , sidebarFooter = span [] []
      }
    Just currentNote ->
      { sidebarBody   = lazy  viewCurrentNoteBody            currentNote
      , sidebarFooter = lazy2 viewCurrentNoteFooter channels currentNote
      }
  in
    div [id "right-sidebar-container", class "sidebar"] [
      div [id "right-sidebar-header", class "sidebar-header"] [
        input [id "notes-search-text", class "sidebar-header-control", placeholder "search notes",
          onKeyUp (\_ -> send channels.searchNotes ())] [],
        span [id "notes-search-button", class "sidebar-header-control flaticon-pencil90",
          onClick <| send channels.newNote ()] []
      ],
      div [id "right-sidebar-body", class "sidebar-body"] [
        sidebarBody
      ],
      sidebarFooter
    ]

viewNoteListings updateChannel notes =
  div [id "note-listings"] <| map (viewNoteListing updateChannel) notes

viewNoteListing : LocalChannel Update -> Note -> Html
viewNoteListing updateChannel note =
  div [key ("note-" ++ note.id), class "note-listing",
    onClick <| send updateChannel (SetCurrentNote (Just note))] [
      div [class "flaticon-document127 note-listing-icon"] [],
      div [class "note-listing-title"] [text note.title]
    ]

viewCurrentNoteBody : Note -> Html
viewCurrentNoteBody note =
  div [key ("current-note-" ++ note.id), id "current-note"] [
    div [id "current-note-title-container"] [
      div [id "current-note-title"] [text note.title]
    ],
    div [id "current-note-body"] []
  ]

viewCurrentNoteFooter : Channels a -> Note -> Html
viewCurrentNoteFooter channels note =
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