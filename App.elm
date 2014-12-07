module App where

import Dreamwriter (..)
import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Component.Page (view)

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

debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

-- ACTIONS --

step : Action -> AppState -> AppState
step action state =
  case action of
    NoOp -> state

    OpenDocId id ->
      {state | currentDocId    <- Just id
             , leftSidebarView <- CurrentDocView
      }

    LoadAsCurrentDoc doc ->
      let stateAfterOpenDocId = step (OpenDocId doc.id) state
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

    SetLeftSidebarView mode ->
      {state | leftSidebarView <- mode}

    PutSnapshot snapshot ->
      {state | snapshots <- Dict.insert snapshot.id snapshot state.snapshots}

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

preferById preferred given =
  if preferred.id == given.id
    then preferred
    else given

main : Signal Element
main = Signal.map2 scene state Window.dimensions

userInput : Signal Action
userInput =
  mergeMany
  [ Signal.map LoadAsCurrentDoc loadAsCurrentDoc
  , Signal.map ListDocs         listDocs
  , Signal.map ListNotes        listNotes
  , Signal.map SetChapters      setChapters
  , Signal.map UpdateChapter    updateChapter
  , Signal.map SetTitle         setTitle
  , Signal.map SetDescription   setDescription
  , Signal.map SetFullscreen    setFullscreen
  , Signal.map PutSnapshot      putSnapshot
  , Signal.map SetCurrentNote   setCurrentNote
  , Signal.subscribe actions
  ]

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState userInput

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

port setCurrentDocId : Signal (Maybe Identifier)
port setCurrentDocId = Signal.map .currentDocId state

port newDoc : Signal ()
port newDoc = Signal.subscribe newDocChannel

port openFromFile : Signal ()
port openFromFile = Signal.subscribe openFromFileChannel

port downloadDoc : Signal DownloadOptions
port downloadDoc = Signal.subscribe downloadChannel

port printDoc : Signal ()
port printDoc = Signal.subscribe printChannel

port navigateToChapterId : Signal Identifier
port navigateToChapterId = Signal.subscribe navigateToChapterIdChannel

port navigateToTitle : Signal ()
port navigateToTitle = Signal.subscribe navigateToTitleChannel

port newNote : Signal ()
port newNote = Signal.subscribe newNoteChannel

port newChapter : Signal ()
port newChapter = Signal.subscribe newChapterChannel

port searchNotes : Signal ()
port searchNotes = debounce 500 <| Signal.subscribe searchNotesChannel

port fullscreen : Signal Bool
port fullscreen = Signal.subscribe fullscreenChannel

port execCommand : Signal String
port execCommand = Signal.subscribe execCommandChannel