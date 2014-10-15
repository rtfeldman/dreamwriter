module Dreamwriter.Doc (Doc, Chapter) where

import Dreamwriter (Identifier)
import Maybe
import String

type Doc =
  { id          : Identifier
  , title       : String
  , chapters    : [Chapter]
  }

type Chapter =
  { heading     : String
  }
