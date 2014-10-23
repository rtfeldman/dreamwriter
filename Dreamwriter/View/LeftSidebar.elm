module Dreamwriter.View.LeftSidebar (view) where

import Dreamwriter.Action (..)
import Dreamwriter.Model (..)
import Dreamwriter.View.CurrentDoc as CurrentDoc
import Dreamwriter.View.OpenMenu as OpenMenu

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Html.Optimize.RefEq as RefEq
import Maybe
import Regex (..)

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
      onclick newChapterInput.handle (always ()),
      class "flaticon-add139"] []]

view : Doc -> AppState -> Html
view currentDoc state =
  let {sidebarHeader, sidebarBody, sidebarFooter} = case state.leftSidebarView of
    OpenMenuView  ->
      { sidebarHeader = viewOpenMenuHeader
      , sidebarBody   = RefEq.lazy2 OpenMenu.view state.docs currentDoc
      , sidebarFooter = viewOpenMenuFooter
      }
    CurrentDocView ->
      { sidebarHeader = RefEq.lazy viewCurrentDocHeader currentDoc
      , sidebarBody   = RefEq.lazy CurrentDoc.view currentDoc
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
      onclick actions.handle (\_ -> SetLeftSidebarView CurrentDocView)] [text "cancel"]
  ]

viewCurrentDocHeader currentDoc =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    div [key ("current-doc-header-" ++ currentDoc.title), id sidebarHeaderId, class sidebarHeaderClass] [
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