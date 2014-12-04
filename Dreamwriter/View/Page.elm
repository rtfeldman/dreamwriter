module Dreamwriter.View.Page where

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
    viewMode   = case model.leftSidebarView of
      CurrentDocView -> LeftSidebar.CurrentDocMode
      OpenMenuView   -> LeftSidebar.OpenMenuMode
  }

leftSidebarToAction : LeftSidebar.Update -> Action.Action
leftSidebarToAction update =
  case update of
    LeftSidebar.NoOp -> Action.NoOp

    LeftSidebar.ViewModeChange mode ->
      Action.SetLeftSidebarView <| case mode of
        LeftSidebar.CurrentDocMode -> CurrentDocView
        LeftSidebar.OpenMenuMode   -> OpenMenuView

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

leftSidebarChannels : LeftSidebar.Channels
leftSidebarChannels = {
    print      = LC.create identity            Action.printChannel,
    newDoc     = LC.create identity            Action.newDocChannel,
    newChapter = LC.create identity            Action.newChapterChannel,
    download   = LC.create identity            Action.downloadChannel,
    update     = LC.create leftSidebarToAction Action.actions
  }

rightSidebarChannels : RightSidebar.Channels
rightSidebarChannels = {
    newNote     = LC.create identity             Action.newNoteChannel,
    searchNotes = LC.create identity             Action.searchNotesChannel,
    update      = LC.create rightSidebarToAction Action.actions
  }

editorChannels : Editor.Channels
editorChannels = {
    fullscreen  = LC.create identity Action.fullscreenChannel,
    execCommand = LC.create identity Action.execCommandChannel
  }

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
