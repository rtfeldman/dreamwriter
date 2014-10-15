module Dreamwriter.View.OpenMenu (view) where

import Dreamwriter.Doc (..)
import Dreamwriter.Action (..)

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)

-- TODO remove this once it's in elm-html
key = attr "key"

view : [Doc] -> Doc -> Html
view docs currentDoc =
  -- Prefer the current doc over the docs in the list, since it is refreshed
  -- more often and thus may have more up-to-date information. (Noticeable if
  -- the user is editing the title in real-time with the Open menu showing.)
  let docsPreferringCurrent = map (preferDoc currentDoc) docs

      sortedDocs : [Doc]
      sortedDocs = sortBy (negate << .lastModifiedTime) docsPreferringCurrent

      docNodes : [Html]
      docNodes = map (viewOpenDocEntryFor currentDoc) sortedDocs

      openFileNodes : [Html]
      openFileNodes = [
        input [id "openFileChooser", key "openFileChooser", value "",
          --onchange handleFileChooserChange, 
          (attr "type" "file"), multiple True, accept "text/html"] [],

        div [class "open-entry", key "open-local-file"
            --, onclick handleShowOpenFile
          ] [
            span [key "open-local-file-1"] [text "A "],
            b    [key "open-local-file-2"] [text ".html"],
            span [key "open-local-file-3"] [text " file from your computer..."]
          ]
      ]
  in
    div [id "open", key "open"] (openFileNodes ++ docNodes)

viewOpenDocEntryFor : Doc -> Doc -> Html
viewOpenDocEntryFor currentDoc doc =
  let className = if doc.id == currentDoc.id
    then "open-entry current"
    else "open-entry"
  in
    div [class className, key ("open-doc-" ++ doc.id),
      onclick actions.handle (\_ -> OpenDocId doc.id)] [text doc.title]

preferDoc : Doc -> Doc -> Doc
preferDoc preferredDoc doc =
  if doc.id == preferredDoc.id
    then preferredDoc
    else doc