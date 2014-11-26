module Dreamwriter.Model where

import Dreamwriter (Identifier)
import Dict

data LeftSidebarView = CurrentDocView | OpenMenuView

type alias MsSinceEpoch = Int
type alias HtmlString   = String

-- TODO make this a proper ADT once outbound ports can accept them
type alias FullscreenState = Bool

type alias AppState =
  { leftSidebarView : LeftSidebarView
  , docs         : [Doc]
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  , currentNote  : Maybe Note
  , notes        : [Note]
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

type alias Note =
  { id               : Identifier
  , title            : String
  , snapshotId       : HtmlString
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

type alias Doc =
  { id               : Identifier
  , title            : String
  , description      : HtmlString
  , chapters         : [Chapter]
  , titleWords       : Int
  , descriptionWords : Int
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

type alias Chapter =
  { id               : Identifier
  , heading          : String
  , headingWords     : Int
  , bodyWords        : Int
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  , snapshotId       : Identifier
  }

type alias Snapshot =
  { id               : Identifier
  , html             : String
  , text             : String
  }
