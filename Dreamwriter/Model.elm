module Dreamwriter.Model where

import Dreamwriter.Doc (..)
import Dreamwriter (Identifier)

type AppState =
  { showOpenMenu : Bool
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  }

emptyState : AppState
emptyState =
  { showOpenMenu = False
  , currentDoc   = Nothing
  , currentDocId = Nothing
  }
