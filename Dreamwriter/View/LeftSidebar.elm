module Dreamwriter.View.LeftSidebar (view) where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.Doc (..)
import Dreamwriter.View.CurrentDoc as CurrentDoc
import Dreamwriter.View.OpenMenu as OpenMenu

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Maybe

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing ->
      span [] []
    Just currentDoc ->
      let {headerNodes, bodyNode} = case state.leftSidebarView of
        OpenMenuView  ->
          { headerNodes = [
              span [class "sidebar-header-control",
                onclick actions.handle (\_ -> SetLeftSidebarView CurrentDocView)] [text "cancel"]
            ]

          , bodyNode = OpenMenu.view state.docs currentDoc
          }
        CurrentDocView ->
          { headerNodes = [
              span [class "sidebar-header-control",
                onclick newDocInput.handle (always ())] [text "new"],
              span [class "sidebar-header-control",
                onclick actions.handle (\_ -> SetLeftSidebarView OpenMenuView)] [text "open"]
            ]

          , bodyNode = CurrentDoc.view currentDoc
          }
      in
        div [id "left-sidebar-container", class "sidebar"] [
          div [id "left-sidebar-header", class "sidebar-header"] headerNodes,
          div [id "left-sidebar-body"] [bodyNode]
        ]
