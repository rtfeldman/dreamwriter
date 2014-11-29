module Dreamwriter.View.LeftSidebar (view) where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.View.CurrentDoc as CurrentDoc
import Dreamwriter.View.OpenMenu as OpenMenu

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Maybe
import Regex (..)
import Signal (send)

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

viewOpenMenuFooter : Html
viewOpenMenuFooter = span [] []

viewCurrentDocFooter : Html
viewCurrentDocFooter =
  div [id "left-sidebar-footer", class "sidebar-footer"] [
    span [id "add-chapter",
      title "Add Chapter",
      onClick <| send newChapterChannel (),
      class "flaticon-plus81"] []]

view : Doc -> AppState -> Html
view currentDoc state =
  let {sidebarHeader, sidebarBody, sidebarFooter} = case state.leftSidebarView of
    OpenMenuView  ->
      { sidebarHeader = viewOpenMenuHeader
      , sidebarBody   = lazy2 OpenMenu.view state.docs currentDoc
      , sidebarFooter = viewOpenMenuFooter
      }
    CurrentDocView ->
      { sidebarHeader = lazy viewCurrentDocHeader currentDoc
      , sidebarBody   = lazy CurrentDoc.view currentDoc
      , sidebarFooter = viewCurrentDocFooter
      }
  in
    div [id "left-sidebar-container", class "sidebar"] [
      sidebarHeader,
      div [id "left-sidebar-body", class "sidebar-body"] [sidebarBody],
      sidebarFooter
    ]

sidebarHeaderId    = "left-sidebar-header"
sidebarHeaderClass = "sidebar-header"

viewOpenMenuHeader =
  div [key "open-menu-header", id sidebarHeaderId, class sidebarHeaderClass] [
    span [class "sidebar-header-control",
      onClick <| send actions (SetLeftSidebarView CurrentDocView)] [text "cancel"]
  ]

viewCurrentDocHeader currentDoc =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    menu [id sidebarHeaderId, class sidebarHeaderClass] [
      menuitem [
        title "New",
        class "sidebar-header-control flaticon-add26",
        onClick <| send newDocChannel ()] [],
      menuitem [
        title "Open",
        class "sidebar-header-control flaticon-folder63",
        onClick <| send actions (SetLeftSidebarView OpenMenuView)] [],
      menuitem [
        title "Download",
        class "sidebar-header-control flaticon-cloud134",
        onClick <| send downloadChannel downloadOptions] [],
      menuitem [
        title "Print",
        class "sidebar-header-control flaticon-printer70",
        onClick <| send printChannel ()] [],
      menuitem [
        title "Settings",
        class "sidebar-header-control flaticon-gear33"] []
    ]