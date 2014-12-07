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

view : AppState -> Html
view model =
  let updateLeftSidebar    = LC.create (leftSidebarToAction model)  Action.actions
      updateRightSidebar   = LC.create (rightSidebarToAction model) Action.actions
      leftSidebarChannels  = { channels | update = updateLeftSidebar  }
      rightSidebarChannels = { channels | update = updateRightSidebar }
      editorChannels       = channels
  in div [id "page"] <|
    case model.currentDoc of
      Nothing -> []
      Just currentDoc ->
        [
          LeftSidebar.view  leftSidebarChannels  (modelLeftSidebar currentDoc model),
          Editor.view       editorChannels       (modelEditor currentDoc model),
          RightSidebar.view rightSidebarChannels (modelRightSidebar model)
        ]

modelLeftSidebar : Doc -> AppState -> LeftSidebar.Model
modelLeftSidebar currentDoc model = {
    docs       = model.docs,
    currentDoc = currentDoc,
    viewMode   = model.leftSidebar.viewMode
  }

modelEditor : Doc -> AppState -> Editor.Model
modelEditor currentDoc model = {
    currentDoc = currentDoc,
    fullscreen = model.fullscreen
  }

modelRightSidebar : AppState -> RightSidebar.Model
modelRightSidebar model = {
    currentNote = model.currentNote,
    notes       = model.notes
  }

leftSidebarToAction : AppState -> LeftSidebar.Update -> Action.Action
leftSidebarToAction model update =
  Action.SetLeftSidebar (LeftSidebar.step update model.leftSidebar)

rightSidebarToAction : AppState -> RightSidebar.Update -> Action.Action
rightSidebarToAction model update =
  Action.SetRightSidebar (RightSidebar.step update model.rightSidebar)