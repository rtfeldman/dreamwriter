module App where

import Dreamwriter exposing (..)
import Dreamwriter.Mailboxes exposing (signals, addresses)
import Dreamwriter.Mailboxes as Mailboxes
import Component.Page as Page

import Component.LeftSidebar as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor as Editor

import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Signal
import Signal exposing (Signal)
import Time exposing (Time, since)
import List exposing (..)
import Maybe
import Window
import Dict
import Set


debounce : Time -> Signal a -> Signal a
debounce wait signal =
    Signal.sampleOn (since wait signal |> Signal.dropRepeats) signal


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
updates =
    Signal.mailbox NoOp


type alias AppState =
    { page         : Page.Model
    , fullscreen   : FullscreenState
    , currentDoc   : Maybe Doc
    , currentDocId : Maybe Identifier
    , currentNote  : Maybe Note
    , docs         : List Doc
    , notes        : List Note
    , snapshots    : Dict.Dict Identifier Snapshot
    }


initialState : AppState
initialState =
    { page         = Page.initialModel
    , fullscreen   = False
    , currentDoc   = Nothing
    , currentDocId = Nothing
    , currentNote  = Nothing
    , docs         = []
    , notes        = []
    , snapshots    = Dict.empty
    }


transition : Update -> AppState -> AppState
transition action state =
    case action of
        NoOp ->
            state

        OpenDocId id ->
            let
                initialPage =
                    Page.initialModel

                page =
                    { initialPage
                    | currentDocId <- Just id
                    , currentDoc   <- state.currentDoc
                    , docs         <- state.docs
                    , notes        <- state.notes
                    , fullscreen   <- state.fullscreen
                    }
            in
                { state
                | currentDocId <- Just id
                , page <- page
                }

        LoadAsCurrentDoc doc ->
            let
                stateAfterOpenDocId =
                    transition (OpenDocId doc.id) state

                newState =
                    { stateAfterOpenDocId | currentDoc <- Just doc }
            in
                updateCurrentDoc (always doc) newState
                    |> pruneSnapshots

        ListDocs docs ->
            { state | docs <- docs }

        ListNotes notes ->
            { state | notes <- notes }

        SetCurrentNote currentNote ->
            { state | currentNote <- currentNote }

        SetChapters chapters ->
            let
                updateDoc doc =
                    { doc | chapters <- chapters }
            in
                updateCurrentDoc updateDoc state
                    |> pruneSnapshots

        UpdateChapter chapter ->
            let
                updateDoc doc =
                    { doc
                    | chapters <- List.map (preferById chapter) doc.chapters
                    }
            in
                updateCurrentDoc updateDoc state
                    |> pruneSnapshots

        SetTitle (title, words) ->
            let
                updateDoc doc =
                    { doc | title <- title, titleWords <- words }
            in
                updateCurrentDoc updateDoc state

        SetDescription (description, words) ->
            let
                updateDoc doc =
                    { doc
                    | description <- description
                    , descriptionWords <- words
                    }
            in
                updateCurrentDoc updateDoc state

        SetFullscreen enabled ->
            { state | fullscreen <- enabled }

        PutSnapshot snapshot ->
            { state
            | snapshots <- Dict.insert snapshot.id snapshot state.snapshots
            }

        SetPage model ->
            { state
            | page         <- model
            , currentDocId <- model.currentDocId
            , currentNote  <- model.currentNote
            }


-- Throw out any snapshots that are no longer relevant, so they can be GC'd.
pruneSnapshots : AppState -> AppState
pruneSnapshots state =
    case state.currentDoc of
        Nothing ->
            state

        Just currentDoc ->
            let
                allSnapshotIds =
                    currentDoc.chapters
                        |> List.map .snapshotId
                        |> Set.fromList

                newSnapshots =
                    state.snapshots
                        |> Dict.filter (\id _ -> Set.member id allSnapshotIds)
            in
                { state | snapshots <- newSnapshots }


updateCurrentDoc : (Doc -> Doc) -> AppState -> AppState
updateCurrentDoc transformation state =
    case state.currentDoc of
        Nothing ->
            state

        Just currentDoc ->
            let
                newCurrentDoc =
                    transformation currentDoc

                newDocs =
                    List.map (preferById newCurrentDoc) state.docs
            in
                { state
                | currentDoc <- Just newCurrentDoc
                , docs       <- newDocs
                }


preferById : { a | id : b } -> { a | id : b } -> { a | id : b }
preferById preferred given =
    if preferred.id == given.id then
        preferred
    else
        given


main : Signal Html
main =
    Signal.map scene state


userInput : Signal Update
userInput =
    Signal.mergeMany
        [ Signal.map LoadAsCurrentDoc loadAsCurrentDoc
        , Signal.map ListDocs listDocs
        , Signal.map ListNotes listNotes
        , Signal.map SetChapters setChapters
        , Signal.map UpdateChapter updateChapter
        , Signal.map SetTitle setTitle
        , Signal.map SetDescription setDescription
        , Signal.map SetFullscreen setFullscreen
        , Signal.map PutSnapshot putSnapshot
        , Signal.map SetCurrentNote setCurrentNote
        , updates.signal
        ]


generalizePageUpdate : AppState -> Page.Update -> Update
generalizePageUpdate state pageUpdate =
    SetPage (Page.transition pageUpdate state.page)


modelPage : AppState -> Page.Model
modelPage state =
    { leftSidebar = state.page.leftSidebar
    , rightSidebar = state.page.rightSidebar
    , editor = state.page.editor
    , fullscreen = state.fullscreen
    , currentDocId = state.currentDocId
    , currentDoc = state.currentDoc
    , currentNote = state.currentNote
    , docs = state.docs
    , notes = state.notes
    }

scene : AppState -> Html
scene state =
    let
        pageUpdate =
            Signal.forwardTo updates.address (generalizePageUpdate state)

        addresses =
            Mailboxes.addresses

    in
        Page.view { addresses | update = pageUpdate } (modelPage state)


-- manage the state of our application over time
state : Signal AppState
state =
    Signal.foldp transition initialState userInput


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
port setCurrentDocId =
    Signal.map .currentDocId state


port newDoc : Signal ()
port newDoc =
    signals.newDoc


port openFromFile : Signal ()
port openFromFile =
    signals.openFromFile


port downloadDoc : Signal DownloadOptions
port downloadDoc =
    signals.download


port printDoc : Signal ()
port printDoc =
    signals.print


port navigateToChapterId : Signal Identifier
port navigateToChapterId =
    signals.navigateToChapterId


port navigateToTitle : Signal ()
port navigateToTitle =
    signals.navigateToTitle


port newNote : Signal ()
port newNote =
    signals.newNote


port openNoteId : Signal Identifier
port openNoteId =
    signals.openNoteId


port newChapter : Signal ()
port newChapter =
    signals.newChapter


port searchNotes : Signal String
port searchNotes =
    signals.searchNotes
        |> debounce 500


port fullscreen : Signal Bool
port fullscreen =
    signals.fullscreen


port execCommand : Signal String
port execCommand =
    signals.execCommand


port remoteSync : Signal ()
port remoteSync =
    signals.remoteSync
