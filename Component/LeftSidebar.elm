module Component.LeftSidebar where

import Dreamwriter.Model (..)
import Dreamwriter.Action (..) -- TODO refactor out this dependency by passing in the relevant channels as arguments to view

import Component.LeftSidebar.OpenMenuView as OpenMenu
import Component.LeftSidebar.CurrentDocView as CurrentDoc

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Maybe
import Regex (..)
import Signal
import LocalChannel as LC

type ViewMode = CurrentDocMode | OpenMenuMode

type alias Model = {
  viewMode   : ViewMode,
  docs       : List Doc,
  currentDoc : Doc
}

type Update
  = NoOp
  | SetViewMode ViewMode

step : Update -> Model -> Model
step update model =
  case update of
    NoOp -> model

    SetViewMode mode -> { model | viewMode <- mode }

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

view : LC.LocalChannel Update -> Model -> Html
view updates model =
  let {sidebarHeader, sidebarBody, sidebarFooter} = case model.viewMode of
    OpenMenuMode  -> {
      sidebarHeader = viewOpenMenuHeader updates,
      sidebarBody   = lazy2 OpenMenu.view model.docs model.currentDoc,
      sidebarFooter = viewOpenMenuFooter
    }

    CurrentDocMode -> {
      --sidebarHeader = lazy <| viewCurrentDocHeader model.currentDoc updates,
      sidebarHeader = viewCurrentDocHeader model.currentDoc updates,
      sidebarBody   = lazy CurrentDoc.view model.currentDoc,
      sidebarFooter = viewCurrentDocFooter
    }
  in
    div [id "left-sidebar-container", class "sidebar"] [
      sidebarHeader,
      div [id "left-sidebar-body", class "sidebar-body"] [sidebarBody],
      sidebarFooter
    ]

sidebarHeaderId    = "left-sidebar-header"
sidebarHeaderClass = "sidebar-header"

viewOpenMenuFooter : Html
viewOpenMenuFooter = span [] []

viewCurrentDocFooter : Html
viewCurrentDocFooter =
  div [id "left-sidebar-footer", class "sidebar-footer"] [
    span [id "add-chapter",
      title "Add Chapter",
      onClick <| Signal.send newChapterChannel (),
      class "flaticon-plus81"] []]

viewOpenMenuHeader updates =
  div [key "open-menu-header", id sidebarHeaderId, class sidebarHeaderClass] [
    span [class "sidebar-header-control",
      onClick <| LC.send updates (SetViewMode CurrentDocMode)] [text "cancel"]
  ]

viewCurrentDocHeader : Doc -> LC.LocalChannel Update -> Html
viewCurrentDocHeader currentDoc updates =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    menu [id sidebarHeaderId, class sidebarHeaderClass] [
      menuitem [
        title "New",
        class "sidebar-header-control flaticon-add26",
        onClick <| Signal.send newDocChannel ()] [],
      menuitem [
        title "Open",
        class "sidebar-header-control flaticon-folder63",
        onClick <| LC.send updates (SetViewMode OpenMenuMode)] [],
      menuitem [
        title "Download",
        class "sidebar-header-control flaticon-cloud134",
        onClick <| Signal.send downloadChannel downloadOptions] [],
      menuitem [
        title "Print",
        class "sidebar-header-control flaticon-printer70",
        onClick <| Signal.send printChannel ()] [],
      menuitem [
        title "Settings",
        class "sidebar-header-control flaticon-gear33"] []
    ]