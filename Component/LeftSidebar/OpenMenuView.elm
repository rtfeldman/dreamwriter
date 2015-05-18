module Component.LeftSidebar.OpenMenuView (view) where

import Dreamwriter exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import Signal exposing (Message, Address)

view : Address () -> Address Identifier -> List Doc -> Doc -> Html
view openFromFile openDoc docs currentDoc =
  let sortedDocs : List Doc
      sortedDocs = sortBy (negate << .lastModifiedTime) docs

      docNodes : List Html
      docNodes = map (viewOpenDocEntryFor openDoc currentDoc) sortedDocs

      openFileNodes : List Html
      openFileNodes = [
        div [class "open-entry from-file",
            onClick openFromFile ()
          ] [
            span [] [text "A "],
            b    [] [text ".html"],
            span [] [text " file from your computer..."]
          ]
      ]
  in
    div [key "open-menu-view", id "open"] (openFileNodes ++ docNodes)

viewOpenDocEntryFor : Address Identifier -> Doc -> Doc -> Html
viewOpenDocEntryFor openDoc currentDoc doc =
  let className = if doc.id == currentDoc.id
    then "open-entry current"
    else "open-entry"
  in
    div [key ("#open-doc-" ++ doc.id), class className,
      onClick openDoc doc.id] [text doc.title]
