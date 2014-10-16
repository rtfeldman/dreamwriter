module Dreamwriter.Model where

import Dreamwriter.Doc (..)
import Dreamwriter (Identifier)

data LeftSidebarView = CurrentDocView | OpenMenuView

type AppState =
  { leftSidebarView : LeftSidebarView
  , docs         : [Doc]
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  }

emptyState : AppState
emptyState =
  { leftSidebarView = CurrentDocView
  , docs         = []
  , currentDoc   = Nothing
  , currentDocId = Nothing
  }
