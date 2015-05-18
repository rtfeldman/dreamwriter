module Component.Page where

import Dreamwriter exposing (..)

import Component.LeftSidebar  as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor       as Editor

import String
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Signal exposing (Address)

type Update
  = NoOp
  | SetLeftSidebar  LeftSidebar.Model
  | SetRightSidebar RightSidebar.Model
  | SetEditor       Editor.Model

type alias Model = {
  leftSidebar  : LeftSidebar.Model,
  rightSidebar : RightSidebar.Model,
  editor       : Editor.Model,

  fullscreen   : FullscreenState,

  currentDocId : Maybe Identifier,
  currentDoc   : Maybe Doc,
  currentNote  : Maybe Note,

  docs         : List Doc,
  notes        : List Note
}

initialModel : Model
initialModel = {
    leftSidebar  = LeftSidebar.initialModel,
    rightSidebar = RightSidebar.initialModel,
    editor       = Editor.initialModel,

    fullscreen   = False,

    currentDocId = Nothing,
    currentDoc   = Nothing,
    currentNote  = Nothing,

    docs         = [],
    notes        = []
  }

transition : Update -> Model -> Model
transition update model =
  case update of
    NoOp -> model

    SetLeftSidebar  childModel -> { model |
      leftSidebar  <- childModel,
      currentDocId <- childModel.currentDocId
    }

    SetRightSidebar childModel -> { model |
      rightSidebar <- childModel,
      currentNote  <- childModel.currentNote
    }

    SetEditor       childModel -> { model | editor       <- childModel }

type Action
  = NoAction
  | NewDoc
  | OpenFromFile
  | NavigateToTitle
  | NavigateToChapterId Identifier
  | Download DownloadOptions
  | NewChapter
  | Print
  | UpdateModel Update

fromLeftSidebarAction : Model -> LeftSidebar.Action -> Action
fromLeftSidebarAction model action =
  case action of
    LeftSidebar.NoAction -> NoAction
    LeftSidebar.NewDoc -> NewDoc
    LeftSidebar.OpenFromFile -> OpenFromFile
    LeftSidebar.NavigateToTitle -> NavigateToTitle
    LeftSidebar.NavigateToChapterId id -> NavigateToChapterId id
    LeftSidebar.Download options -> Download options
    LeftSidebar.NewChapter -> NewChapter
    LeftSidebar.Print -> Print
    LeftSidebar.UpdateModel update ->
      UpdateModel <| SetLeftSidebar <| LeftSidebar.transition update model.leftSidebar

view actions addresses model =
  let leftSidebarActions   : Address LeftSidebar.Action
      leftSidebarActions   = Signal.forwardTo actions (fromLeftSidebarAction model)

      rightSidebarChannels = addresses
      editorChannels       = addresses
  in div [id "page"] <|
    case model.currentDoc of
      Nothing -> []
      Just currentDoc ->
        [
          LeftSidebar.view  leftSidebarActions   (modelLeftSidebar currentDoc model),
          Editor.view       editorChannels       (modelEditor currentDoc model),
          RightSidebar.view rightSidebarChannels (modelRightSidebar model)
        ]

modelLeftSidebar : Doc -> Model -> LeftSidebar.Model
modelLeftSidebar currentDoc model = {
    docs         = model.docs,
    currentDoc   = currentDoc,
    currentDocId = model.currentDocId,
    viewMode     = model.leftSidebar.viewMode
  }

modelEditor : Doc -> Model -> Editor.Model
modelEditor currentDoc model = {
    currentDoc = currentDoc,
    fullscreen = model.fullscreen
  }

modelRightSidebar : Model -> RightSidebar.Model
modelRightSidebar model = {
    currentNote = model.currentNote,
    notes       = model.notes
  }
