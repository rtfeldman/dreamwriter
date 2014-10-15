module Dreamwriter.Model where

import Dreamwriter.Doc (..)
import Dreamwriter (Identifier)

type AppState =
  { showOpenMenu : Bool
  , docs         : [Doc]
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  }

emptyState : AppState
emptyState =
  { showOpenMenu = False
  , docs         = []
  , currentDoc   = Nothing
  , currentDocId = Nothing
  }
