module Component.LeftSidebar.CurrentDocView (view) where

import Dreamwriter exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import Signal exposing (Address)


view : Address () -> Address Identifier -> Doc -> Html
view navigateToTitle navigateToChapterId currentDoc =
    div
        [ key "current-doc-view", id "current-doc-view" ]
        [ div
            [ id "title", onClick navigateToTitle () ]
            [ text currentDoc.title ]
        , viewOutline navigateToChapterId currentDoc.chapters
        ]


viewOutline : Address Identifier -> List Chapter -> Html
viewOutline navigateToChapterId chapters =
    ul [ id "outline" ] <| indexedMap (viewChapter navigateToChapterId) chapters


viewChapter : Address Identifier -> Int -> Chapter -> Html
viewChapter navigateToChapterId index chapter =
    li
        [ key ("chapter" ++ (toString index))
        , title chapter.heading
        , onClick navigateToChapterId chapter.id
        ]
        [ text chapter.heading ]
