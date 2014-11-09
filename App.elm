module App where

import Dreamwriter (Identifier)
import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.View.Page (view)

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Html.Optimize.RefEq as Ref
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

    SetTitle title ->
      updateCurrentDoc (\doc -> {doc | title <- title}) state

    SetDescription description ->
      updateCurrentDoc (\doc -> {doc | description <- description}) state

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
updateCurrentDoc transformCurrentDoc state =
  case state.currentDoc of
    Nothing         -> state
    Just currentDoc ->
      let newCurrentDoc = transformCurrentDoc currentDoc
          newDocs       = map (preferDoc newCurrentDoc) state.docs
      in
        {state | currentDoc <- Just newCurrentDoc
               , docs       <- newDocs
        }

preferDoc : Doc -> Doc -> Doc
preferDoc preferredDoc doc =
  if doc.id == preferredDoc.id
    then preferredDoc
    else doc

main : Signal Element
main = lift2 scene state Window.dimensions

userInput : Signal Action
userInput =
  merges
  [ lift LoadAsCurrentDoc loadAsCurrentDoc
  , lift ListDocs         listDocs
  , lift ListNotes        listNotes
  , lift SetChapters      setChapters
  , lift SetTitle         setTitle
  , lift SetDescription   setDescription
  , lift SetFullscreen    setFullscreen
  , lift PutSnapshot      putSnapshot
  , actions.signal
  ]

scene : AppState -> (Int, Int) -> Element
scene state (w, h) =
  container w h midTop (toElement w h (view state))

-- manage the state of our application over time
state : Signal AppState
state = foldp step emptyState userInput

-- PORTS --

port loadAsCurrentDoc : Signal Doc
port setChapters : Signal [Chapter]
port setTitle : Signal String
port setDescription : Signal String
port setFullscreen : Signal Bool
port listDocs : Signal [Doc]
port listNotes : Signal [Note]
port putSnapshot : Signal Snapshot

port setCurrentDocId : Signal (Maybe Identifier)
port setCurrentDocId = lift .currentDocId state

port newDoc : Signal ()
port newDoc = newDocInput.signal

port openFromFile : Signal ()
port openFromFile = openFromFileInput.signal

port downloadDoc : Signal DownloadOptions
port downloadDoc = downloadInput.signal

port printDoc : Signal ()
port printDoc = printInput.signal

port navigateToChapterId : Signal Identifier
port navigateToChapterId = navigateToChapterIdInput.signal

port navigateToTitle : Signal ()
port navigateToTitle = navigateToTitleInput.signal

port newNote : Signal ()
port newNote = newNoteInput.signal

port newChapter : Signal ()
port newChapter = newChapterInput.signal

port searchNotes : Signal ()
port searchNotes = debounce 500 searchNotesInput.signal

port fullscreen : Signal Bool
port fullscreen = fullscreenInput.signal

port execCommand : Signal String
port execCommand = execCommandInput.signal