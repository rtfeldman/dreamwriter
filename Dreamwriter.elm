module Dreamwriter where

-- TODO make this a proper ADT once outbound ports can accept them
type alias FullscreenState = Bool

type alias Identifier   = String
type alias MsSinceEpoch = Int
type alias HtmlString   = String


type alias DownloadOptions =
    { filename    : String
    , contentType : String
    }


type alias Note =
    { id               : Identifier
    , title            : String
    , snapshotId       : HtmlString
    , creationTime     : MsSinceEpoch
    , lastModifiedTime : MsSinceEpoch
    }


type alias Doc =
  {
    id : Identifier,
    title : String,
    description : HtmlString,
    chapters : List Chapter,
    titleWords : Int,
    descriptionWords : Int,
    creationTime : MsSinceEpoch,
    lastModifiedTime : MsSinceEpoch,
    dailyWords : List WordsPerDay,
    dailyWordsStartsAt : Int
  }

emptyDoc =
  {
    id = "",
    title = "",
    description = "",
    chapters = [],
    titleWords = 0,
    descriptionWords = 0,
    creationTime = 0,
    lastModifiedTime = 0,
    dailyWords = [],
    dailyWordsStartsAt = 0
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

type alias WordsPerDay =
  {
    day : String,
    words : Int
  }

type alias Snapshot =
  { id : Identifier
  , html : String
  , text : String
  }

