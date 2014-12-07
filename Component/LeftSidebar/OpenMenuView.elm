module Component.LeftSidebar.OpenMenuView (view) where

import Dreamwriter (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Signal (send)
import List (..)

view : List Doc -> Doc -> Html
view docs currentDoc =
  let sortedDocs : List Doc
      sortedDocs = sortBy (negate << .lastModifiedTime) docs

      docNodes : List Html
      docNodes = map (viewOpenDocEntryFor currentDoc) sortedDocs

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

viewOpenDocEntryFor : Doc -> Doc -> Html
viewOpenDocEntryFor currentDoc doc =
  let className = if doc.id == currentDoc.id
    then "open-entry current"
    else "open-entry"
  in
    div [key ("#open-doc-" ++ doc.id), class className,
      onClick <| send actions (OpenDocId doc.id)] [text doc.title]
