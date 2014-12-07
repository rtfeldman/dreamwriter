module Component.LeftSidebar.OpenMenuView (view) where

import Dreamwriter (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import LocalChannel (LocalChannel, send)
import List (..)
import Signal (Message)

view : LocalChannel () -> (Identifier -> Message) -> List Doc -> Doc -> Html
view openFromFileChannel openDoc docs currentDoc =
  let sortedDocs : List Doc
      sortedDocs = sortBy (negate << .lastModifiedTime) docs

      docNodes : List Html
      docNodes = map (viewOpenDocEntryFor openDoc currentDoc) sortedDocs

      openFileNodes : List Html
      openFileNodes = [
        div [class "open-entry from-file",
            onClick <| send openFromFileChannel ()
          ] [
            span [] [text "A "],
            b    [] [text ".html"],
            span [] [text " file from your computer..."]
          ]
      ]
  in
    div [key "open-menu-view", id "open"] (openFileNodes ++ docNodes)

viewOpenDocEntryFor : (Identifier -> Message) -> Doc -> Doc -> Html
viewOpenDocEntryFor openDoc currentDoc doc =
  let className = if doc.id == currentDoc.id
    then "open-entry current"
    else "open-entry"
  in
    div [key ("#open-doc-" ++ doc.id), class className,
      onClick <| openDoc doc.id] [text doc.title]
