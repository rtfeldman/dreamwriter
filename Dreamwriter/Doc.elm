module Dreamwriter.Doc (Doc, Chapter) where

import Dreamwriter (Identifier)
import Maybe
import String

type MsSinceEpoch = Int
type HtmlString   = String

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
