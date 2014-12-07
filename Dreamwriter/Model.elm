module Dreamwriter.Model where

import Dreamwriter (..)
import Dict

import Component.LeftSidebar  as LeftSidebar
import Component.RightSidebar as RightSidebar
import Component.Editor       as Editor

type LeftSidebarView = CurrentDocView | OpenMenuView

type alias AppState = {
  leftSidebar  : LeftSidebar.Model,
  rightSidebar : RightSidebar.Model,
  editor       : Editor.Model,
  fullscreen   : FullscreenState,

  currentDoc   : Maybe Doc,
  currentDocId : Maybe Identifier,
  currentNote  : Maybe Note,

  docs         : List Doc,
  notes        : List Note,
  snapshots    : Dict.Dict Identifier Snapshot
}

emptyState : AppState
emptyState = {
    leftSidebar  = LeftSidebar.initialModel,
    rightSidebar = RightSidebar.initialModel,
    editor       = Editor.initialModel,
    fullscreen   = False,

    currentDoc   = Nothing,
    currentDocId = Nothing,
    currentNote  = Nothing,

    docs         = [],
    notes        = [],
    snapshots    = Dict.empty
  }