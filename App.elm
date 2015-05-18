module App where

import Dreamwriter exposing (..)
import Dreamwriter.Mailboxes exposing (signals, addresses)
import Dreamwriter.Mailboxes as Mailboxes
import Component.Page as Page

import Component.LeftSidebar  as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor       as Editor

import String
import Graphics.Element exposing (Element, container, midTop)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Signal
import Signal exposing (Signal, sampleOn, dropRepeats, mergeMany, foldp, forwardTo)
import Time exposing (Time, since)
import List exposing (..)
import Maybe
import Window
import Dict
import Set

debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

-- UPDATES --

type Update
  = NoOp
  | LoadAsCurrentDoc Doc
  | OpenDocId Identifier
  | ListDocs (List Doc)
  | OpenNoteId Identifier
  | ListNotes (List Note)
  | SetCurrentNote (Maybe Note)
  | SetChapters (List Chapter)
  | UpdateChapter Chapter
  | SetTitle (String, Int)
  | SetDescription (String, Int)
  | SetFullscreen FullscreenState
  | PutSnapshot Snapshot
  | SetPage Page.Model

-- updates from user input
updates : Signal.Mailbox Update
updates = Signal.mailbox NoOp

type alias AppState = {
  page         : Page.Model,

  fullscreen   : FullscreenState,

  currentDoc   : Maybe Doc,
  currentDocId : Maybe Identifier,
  currentNote  : Maybe Note,

  docs         : List Doc,
  notes        : List Note,
  snapshots    : Dict.Dict Identifier Snapshot
}

initialState : AppState
initialState = {
    page         = Page.initialModel,

    fullscreen   = False,

    currentDoc   = Nothing,
    currentDocId = Nothing,
    currentNote  = Nothing,

    docs         = [],
    notes        = [],
    snapshots    = Dict.empty
  }

transition : Update -> AppState -> AppState
transition action state =
  case action of
    NoOp -> state

    OpenDocId id ->
      let initialPage = Page.initialModel
          page'       = { initialPage |
            currentDocId <- Just id,
            currentDoc   <- state.currentDoc,
            docs         <- state.docs,
            notes        <- state.notes,
            fullscreen   <- state.fullscreen
          }
      in { state |
        currentDocId <- Just id,
        page         <- page'
      }

    LoadAsCurrentDoc doc ->
      let stateAfterOpenDocId = transition (OpenDocId doc.id) state
          newState = {stateAfterOpenDocId | currentDoc <- Just doc}
      in
        updateCurrentDoc (\_ -> doc) newState
          |> pruneSnapshots

    ListDocs docs ->
      {state | docs <- docs}

    ListNotes notes ->
      {state | notes <- notes}

    SetCurrentNote currentNote ->
      {state | currentNote <- currentNote}

    SetChapters chapters ->
      updateCurrentDoc (\doc -> {doc | chapters <- chapters}) state
        |> pruneSnapshots

    UpdateChapter chapter ->
      updateCurrentDoc (\doc -> {doc | chapters <- (map (preferById chapter) doc.chapters)}) state
        |> pruneSnapshots

    SetTitle (title, words) ->
      updateCurrentDoc (\doc -> {doc | title <- title, titleWords <- words}) state

    SetDescription (description, words) ->
      updateCurrentDoc (\doc -> {doc | description <- description, descriptionWords <- words}) state

    SetFullscreen enabled ->
      {state | fullscreen <- enabled}

    PutSnapshot snapshot ->
      {state | snapshots <- Dict.insert snapshot.id snapshot state.snapshots}

    SetPage model -> { state |
        page         <- model,
        currentDocId <- model.currentDocId,
        currentNote  <- model.currentNote
      }

-- Throw out any snapshots that are no longer relevant, so they can be GC'd.
pruneSnapshots : AppState -> AppState
pruneSnapshots state =
  case state.currentDoc of
    Nothing         -> state
    Just currentDoc ->
      let allSnapshotIds = Set.fromList <| map .snapshotId currentDoc.chapters
          newSnapshots   = state.snapshots
            |> Dict.filter (\id _ -> Set.member id allSnapshotIds)
      in
        {state | snapshots <- newSnapshots}

updateCurrentDoc : (Doc -> Doc) -> AppState -> AppState
updateCurrentDoc transformation state =
  case state.currentDoc of
    Nothing         -> state
    Just currentDoc ->
      let newCurrentDoc = transformation currentDoc
          newDocs       = map (preferById newCurrentDoc) state.docs
      in
        {state | currentDoc <- Just newCurrentDoc
               , docs       <- newDocs
        }

preferById : { a | id : b } -> { a | id : b } -> { a | id : b }
preferById preferred given =
  if preferred.id == given.id
    then preferred
    else given

main : Signal Element
main = Signal.map2 scene state Window.dimensions

userInput : Signal Update
userInput =
  mergeMany [
    Signal.map LoadAsCurrentDoc loadAsCurrentDoc,
    Signal.map ListDocs         listDocs,
    Signal.map ListNotes        listNotes,
    Signal.map SetChapters      setChapters,
    Signal.map UpdateChapter    updateChapter,
    Signal.map SetTitle         setTitle,
    Signal.map SetDescription   setDescription,
    Signal.map SetFullscreen    setFullscreen,
    Signal.map PutSnapshot      putSnapshot,
    Signal.map SetCurrentNote   setCurrentNote,
    updates.signal
  ]

generalizePageUpdate : AppState -> Page.Update -> Update
generalizePageUpdate state pageUpdate = SetPage (Page.transition pageUpdate state.page)

modelPage : AppState -> Page.Model
modelPage state = {
    leftSidebar  = state.page.leftSidebar,
    rightSidebar = state.page.rightSidebar,
    editor       = state.page.editor,

    fullscreen   = state.fullscreen,

    currentDocId = state.currentDocId,
    currentDoc   = state.currentDoc,
    currentNote  = state.currentNote,

    docs         = state.docs,
    notes        = state.notes
  }

actionMailbox = Signal.mailbox Page.NoAction

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  let actions    = actionMailbox.address
      pageUpdate = forwardTo updates.address (generalizePageUpdate state)
      addresses  = Mailboxes.addresses
      html       = Page.view actions { addresses | update = pageUpdate } (modelPage state)
  in
    container w h midTop (toElement w h html)

-- manage the state of our application over time
state : Signal AppState
state = foldp transition initialState userInput

-- PORTS --

port loadAsCurrentDoc : Signal Doc
port setChapters : Signal (List Chapter)
port updateChapter : Signal Chapter
port setTitle : Signal (String, Int)
port setDescription : Signal (String, Int)
port setFullscreen : Signal Bool
port setCurrentNote : Signal (Maybe Note)
port listDocs : Signal (List Doc)
port listNotes : Signal (List Note)
port putSnapshot : Signal Snapshot

portAction : a -> (Page.Action -> Maybe a) -> Signal a
portAction defaultValue filterFunction =
  Signal.filterMap filterFunction defaultValue actionMailbox.signal

port newDoc : Signal ()
port newDoc = portAction () <| \action ->
  case action of
    Page.NewDoc -> Just ()
    _           -> Nothing

port openFromFile : Signal ()
port openFromFile = portAction () <| \action ->
  case action of
    Page.OpenFromFile -> Just ()
    _                 -> Nothing

port downloadDoc : Signal DownloadOptions
port downloadDoc = portAction { filename = "", contentType = "" } <| \action ->
  case action of
    Page.Download options -> Just options
    _                     -> Nothing

port printDoc : Signal ()
port printDoc = portAction () <| \action ->
  case action of
    Page.Print -> Just ()
    _          -> Nothing

port navigateToChapterId : Signal Identifier
port navigateToChapterId = portAction "" <| \action ->
  case action of
    Page.NavigateToChapterId id -> Just id
    _                           -> Nothing

port navigateToTitle : Signal ()
port navigateToTitle = portAction () <| \action ->
  case action of
    Page.NavigateToTitle -> Just ()
    _                    -> Nothing

port newChapter : Signal ()
port newChapter = portAction () <| \action ->
  case action of
    Page.NewChapter -> Just ()
    _               -> Nothing

port setCurrentDocId : Signal (Maybe Identifier)
port setCurrentDocId = Signal.map .currentDocId state

port newNote : Signal ()
port newNote = signals.newNote

port openNoteId : Signal Identifier
port openNoteId = signals.openNoteId

port searchNotes : Signal ()
port searchNotes = debounce 500 <| signals.searchNotes

port fullscreen : Signal Bool
port fullscreen = signals.fullscreen

port execCommand : Signal String
port execCommand = signals.execCommand

port remoteSync : Signal ()
port remoteSync = signals.remoteSync