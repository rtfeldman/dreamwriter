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

-- TODO remove this once it's in elm-html
key = attr "key"

view : AppState -> Html
view state =
  case state.currentDoc of
    Nothing ->
      span [] []
    Just currentDoc ->
      let {headerControls, sidebarBody} = case state.showOpenMenu of
        True  -> 
          { headerControls = [
              span [class "sidebar-header-control", key "cancel",
                onclick actions.handle (\_ -> ToggleOpenMenu False)] [text "cancel"]
            ]

          , sidebarBody = OpenMenu.view state.docs currentDoc
          }
        False ->
          { headerControls = [
              span [class "sidebar-header-control", key "new",
                onclick newDocInput.handle (always ())] [text "new"],
              span [class "sidebar-header-control", key "open",
                onclick actions.handle (\_ -> ToggleOpenMenu True)] [text "open"]
            ]

          , sidebarBody = CurrentDoc.view currentDoc
          }
      in
        div [id "left-sidebar-container", class "sidebar", key "left-sidebar-container"] [
          div [key "left-sidebar-header", id "left-sidebar-header", class "sidebar-header"] headerControls,
          sidebarBody
        ]