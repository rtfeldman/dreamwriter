module Dreamwriter.View.Outline where

import Dreamwriter.Doc (..)

import Html (..)
import Html.Attributes (..)
import Html.Tags (..)

view : [Chapter] -> Html
view chapters =
  ul [id "outline"] <| map viewChapter chapters

viewChapter : Chapter -> Html
viewChapter chapter = li [] [text chapter.heading]
-- TODO put a key on this of "chapter#{index}", e.g. use zipWith