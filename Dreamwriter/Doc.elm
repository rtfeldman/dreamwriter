module Dreamwriter.Doc (Doc, Chapter) where

import Dreamwriter (Identifier)
import Maybe
import String

type MsSinceEpoch = Int

type Doc =
  { id               : Identifier
  , title            : String
  , chapters         : [Chapter]
  , creationTime     : MsSinceEpoch
  , lastModifiedTime : MsSinceEpoch
  }

type Chapter =
  { heading     : String
  }
