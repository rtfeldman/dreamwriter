module Dreamwriter.Model where

import Dreamwriter (Identifier)

data LeftSidebarView = CurrentDocView | OpenMenuView

type MsSinceEpoch = Int
type HtmlString   = String

-- TODO make this a proper ADT once outbound ports can accept them
type FullscreenState = Bool

type AppState =
  { leftSidebarView : LeftSidebarView
  , docs         : [Doc]
  , currentDoc   : Maybe Doc
  , currentDocId : Maybe Identifier
  , currentNote  : Maybe Note
  , notes        : [Note]
  , fullscreen   : FullscreenState
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
  }

type Note =
  { id               : Identifier
  , title            : String
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

type Doc =
  { id               : Identifier
  , title            : String
  , description      : HtmlString
  , chapters         : [Chapter]
  , words            : Int
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

type Chapter =
  { id               : Identifier
  , heading          : String
  , words            : Int
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

preferDoc : Doc -> Doc -> Doc
preferDoc preferredDoc doc =
  if doc.id == preferredDoc.id
    then preferredDoc
    else doc