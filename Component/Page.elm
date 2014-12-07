module Component.Page where

import Dreamwriter (..)
import Dreamwriter.Model (..)
import Dreamwriter.Action as Action
import Component.LeftSidebar  as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor       as Editor

import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import LocalChannel as LC

actionToLeftSidebarModel : Doc -> AppState -> LeftSidebar.Model
actionToLeftSidebarModel currentDoc model = {
    docs       = model.docs,
    currentDoc = currentDoc,
    viewMode   = model.leftSidebar.viewMode
  }

leftSidebarToAction : LeftSidebar.Update -> Action.Action
leftSidebarToAction update =
  case update of
    LeftSidebar.NoOp -> Action.NoOp

    LeftSidebar.ViewModeChange mode ->
      Action.SetLeftSidebarView mode

    LeftSidebar.OpenDocId id -> Action.OpenDocId id

actionToEditorModel : Doc -> AppState -> Editor.Model
actionToEditorModel currentDoc model = {
    currentDoc = currentDoc,
    fullscreen = model.fullscreen
  }

actionToRightSidebarModel : AppState -> RightSidebar.Model
actionToRightSidebarModel model = {
    currentNote = model.currentNote,
    notes       = model.notes
  }

rightSidebarToAction : RightSidebar.Update -> Action.Action
rightSidebarToAction update =
  case update of
    RightSidebar.NoOp                   -> Action.NoOp
    RightSidebar.CurrentNoteChange note -> Action.SetCurrentNote note

channels = {
    fullscreen          = LC.create identity Action.fullscreenChannel,
    execCommand         = LC.create identity Action.execCommandChannel,
    newNote             = LC.create identity Action.newNoteChannel,
    searchNotes         = LC.create identity Action.searchNotesChannel,
    print               = LC.create identity Action.printChannel,
    newDoc              = LC.create identity Action.newDocChannel,
    newChapter          = LC.create identity Action.newChapterChannel,
    download            = LC.create identity Action.downloadChannel,
    openFromFile        = LC.create identity Action.openFromFileChannel,
    navigateToTitle     = LC.create identity Action.navigateToTitleChannel,
    navigateToChapterId = LC.create identity Action.navigateToChapterIdChannel
  }

leftSidebarChannels = { channels |
    update = LC.create leftSidebarToAction Action.actions
  }

rightSidebarChannels = { channels |
    update      = LC.create rightSidebarToAction Action.actions
  }

editorChannels = channels

view : AppState -> Html
view state =
  div [id "page"] <|
    case state.currentDoc of
      Nothing -> []
      Just currentDoc ->
        [
          LeftSidebar.view  leftSidebarChannels  (actionToLeftSidebarModel currentDoc state),
          Editor.view       editorChannels       (actionToEditorModel currentDoc state),
          RightSidebar.view rightSidebarChannels (actionToRightSidebarModel state)
        ]
