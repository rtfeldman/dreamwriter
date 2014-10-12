module Dreamwriter.Model where

import Dreamwriter.Doc (..)
import Dreamwriter (Identifier)

type AppState =
  { showOpenMenu : Bool
  , currentDoc   : Maybe Doc
  , pendingLoad  : (Maybe Identifier, Maybe String)
  }

type Settings =
  { currentDocId : Identifier
  }

emptyState : AppState
emptyState =
  { showOpenMenu    = False
  , currentDoc      = Nothing
  , pendingLoad     = (Nothing, Nothing)
  }
