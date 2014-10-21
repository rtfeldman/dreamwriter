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
import Regex (..)

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

view : Doc -> AppState -> Html
view currentDoc state =
  let {headerNodes, bodyNode} = case state.leftSidebarView of
    OpenMenuView  ->
      { headerNodes = [
          span [class "sidebar-header-control",
            onclick actions.handle (\_ -> SetLeftSidebarView CurrentDocView)] [text "cancel"]
        ]

      , bodyNode = OpenMenu.view state.docs currentDoc
      }
    CurrentDocView ->
      let downloadOptions = {
        filename    = (legalizeFilename currentDoc.title) ++ ".html",
        contentType = downloadContentType
      }
      in
        { headerNodes = [
            span [
              title "New",
              class "sidebar-header-control flaticon-add26",
              onclick newDocInput.handle (always ())] [],
            span [
              title "Open",
              class "sidebar-header-control flaticon-folder63",
              onclick actions.handle (\_ -> SetLeftSidebarView OpenMenuView)] [],
            span [
              title "Download",
              class "sidebar-header-control flaticon-cloud134",
              onclick downloadInput.handle (always downloadOptions)] [],
            span [
              title "Print",
              class "sidebar-header-control flaticon-printer70",
              onclick printInput.handle (always ())] [],
            span [
              title "Settings",
              class "sidebar-header-control flaticon-machine2"] []
          ]

        , bodyNode = CurrentDoc.view currentDoc
        }
  in
    div [id "left-sidebar-container", class "sidebar"] [
      div [id "left-sidebar-header", class "sidebar-header"] headerNodes,
      div [id "left-sidebar-body"] [bodyNode]
    ]
