module Dreamwriter.Model where

import Dreamwriter.Doc (..)

type AppState =
  { docs            : [Doc]
  , openMenuVisible : Bool
  , currentDoc      : Maybe Doc
  }

type Settings =
  { currentDoc : Doc
  }

hackDoc = newDoc "Dreamwriter in Elm!" [newChapter "Foreword", newChapter "Chapter One", newChapter "Chapter Two", newChapter "Epilogue"]

emptyState : AppState
emptyState =
  { docs            = []
  , openMenuVisible = False
  , currentDoc      = Just hackDoc 
  --, currentDoc      = Nothing
  }
