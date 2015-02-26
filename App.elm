module App where

import Dreamwriter (..)
import Dreamwriter.Channel as Channel
import Component.Page as Page

import Component.LeftSidebar  as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor       as Editor

import String
import Graphics.Element (Element, container, midTop)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Signal
import Signal (Signal, sampleOn, dropRepeats, mergeMany, foldp)
import Time (Time, since)
import List (..)
import Maybe
import Window
import Dict
import Set

import LocalChannel as LC

debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

-- UPDATES --

type Update
  = NoOp
  | LoadAsCurrentDoc Doc
  | OpenDocId Identifier
  | ListDocs (List Doc)
  | ListNotes (List Note)
  | SetCurrentNote (Maybe Note)
  | SetChapters (List Chapter)
  | UpdateChapter Chapter
  | SetTitle (String, Int)
  | SetDescription (String, Int)
  | SetFullscreen FullscreenState
  | SetSyncState SyncState
  | PutSnapshot Snapshot
  | SetPage Page.Model

-- updates from user input
updates : Signal.Channel Update
updates = Signal.channel NoOp

type alias AppState = {
  page         : Page.Model,

  fullscreen   : FullscreenState,
  syncState    : SyncState,

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

    syncState    = Initializing,
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

    SetSyncState syncState ->
      {state | syncState <- syncState}

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
    Signal.map syncAccountToUpdate setSyncAccount,
    Signal.subscribe updates
  ]

generalizePageUpdate : AppState -> Page.Update -> Update
generalizePageUpdate state pageUpdate = SetPage (Page.transition pageUpdate state.page)

syncAccountToUpdate : Maybe String -> Update
syncAccountToUpdate account =
  let syncState =
    case account of
      Nothing          -> Initializing
      Just ""          -> Disconnected -- TODO when union types can come through ports, use a union type instead of special-casing empty string to mean "disconnected"
      Just accountName -> Connected accountName
  in SetSyncState syncState

modelPage : AppState -> Page.Model
modelPage state = {
    leftSidebar  = state.page.leftSidebar,
    rightSidebar = state.page.rightSidebar,
    editor       = state.page.editor,

    fullscreen   = state.fullscreen,
    syncState    = state.syncState,

    currentDocId = state.currentDocId,
    currentDoc   = state.currentDoc,
    currentNote  = state.currentNote,

    docs         = state.docs,
    notes        = state.notes
  }

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  let pageUpdate   = LC.create (generalizePageUpdate state) updates
      locals       = Channel.locals
      viewChannels = { locals | update = pageUpdate }
      viewModel    = modelPage state
      html         = Page.view viewChannels viewModel
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
port setSyncAccount : Signal (Maybe String)
port listDocs : Signal (List Doc)
port listNotes : Signal (List Note)
port putSnapshot : Signal Snapshot

port setCurrentDocId : Signal (Maybe Identifier)
port setCurrentDocId = Signal.map .currentDocId state

port newDoc : Signal ()
port newDoc = Signal.subscribe Channel.newDoc

port openFromFile : Signal ()
port openFromFile = Signal.subscribe Channel.openFromFile

port downloadDoc : Signal DownloadOptions
port downloadDoc = Signal.subscribe Channel.download

port printDoc : Signal ()
port printDoc = Signal.subscribe Channel.print

port navigateToChapterId : Signal Identifier
port navigateToChapterId = Signal.subscribe Channel.navigateToChapterId

port navigateToTitle : Signal ()
port navigateToTitle = Signal.subscribe Channel.navigateToTitle

port newNote : Signal ()
port newNote = Signal.subscribe Channel.newNote

port newChapter : Signal ()
port newChapter = Signal.subscribe Channel.newChapter

port searchNotes : Signal ()
port searchNotes = debounce 500 <| Signal.subscribe Channel.searchNotes

port fullscreen : Signal Bool
port fullscreen = Signal.subscribe (Signal.channel False)

port execCommand : Signal String
port execCommand = Signal.subscribe Channel.execCommand

port remoteSync : Signal ()
port remoteSync = Signal.subscribe Channel.remoteSync
