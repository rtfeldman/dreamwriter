module Dreamwriter.Model where

import Dreamwriter (..)
import Dict

type LeftSidebarView = CurrentDocView | OpenMenuView

type alias AppState =
  { leftSidebarView : LeftSidebarView
  , docs         : List Doc
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  , currentNote  : Maybe Note
  , notes        : List Note
  , fullscreen   : FullscreenState
  , snapshots    : Dict.Dict Identifier Snapshot
  }

emptyState : AppState
emptyState =
  { leftSidebarView = CurrentDocView
  , docs         = []
  , currentDoc   = Nothing
  , currentDocId = Nothing
  , currentNote  = Nothing
  , notes        = []
  , fullscreen   = False
  , snapshots    = Dict.empty
  }