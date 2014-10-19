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
      let {headerNodes, bodyNodes} = case state.leftSidebarView of
        OpenMenuView  ->
          { headerNodes = [
              span [key "#cancel-open", class "sidebar-header-control",
                onclick actions.handle (\_ -> SetLeftSidebarView CurrentDocView)] [text "cancel"]
            ]

          , bodyNodes = [OpenMenu.view state.docs currentDoc]
          }
        CurrentDocView ->
          { headerNodes = [
              span [key "#new-doc-button", class "sidebar-header-control",
                onclick newDocInput.handle (always ())] [text "new"],
              span [key "#open-doc-button", class "sidebar-header-control",
                onclick actions.handle (\_ -> SetLeftSidebarView OpenMenuView)] [text "open"]
            ]

          , bodyNodes = CurrentDoc.view currentDoc
          }
      in
        div [key "#left-sidebar-container", id "left-sidebar-container", class "sidebar"] [
          div [key "#left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] headerNodes,
          div [key "#left-sidebar-body", id "left-sidebar-body"] bodyNodes
        ]
