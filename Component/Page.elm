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
import LocalChannel (LocalChannel)
import LocalChannel as LC

type Update
  = NoOp
  | SetLeftSidebar  LeftSidebar.Model
  | SetRightSidebar RightSidebar.Model
  | SetEditor       Editor.Model

type alias Model = {
  leftSidebar  : LeftSidebar.Model,
  rightSidebar : RightSidebar.Model,
  editor       : Editor.Model,

  fullscreen   : FullscreenState
}

initialModel : Model
initialModel = {
    leftSidebar  = LeftSidebar.initialModel,
    rightSidebar = RightSidebar.initialModel,
    editor       = Editor.initialModel,

    fullscreen   = False
  }

view : AppChannels -> AppState -> Html
view channels model =
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