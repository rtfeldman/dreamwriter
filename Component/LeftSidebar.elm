module Component.LeftSidebar where

import Dreamwriter.Model (..)
import Dreamwriter.Action (DownloadOptions)

import Component.LeftSidebar.OpenMenuView as OpenMenu
import Component.LeftSidebar.CurrentDocView as CurrentDoc

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy (..)
import Maybe
import Regex (..)
import LocalChannel (send, LocalChannel)

type ViewMode = CurrentDocMode | OpenMenuMode

type alias Channels = {
  print      : LocalChannel (),
  newDoc     : LocalChannel (),
  newChapter : LocalChannel (),
  download   : LocalChannel DownloadOptions,
  update     : LocalChannel Update
}

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

view : Channels -> Model -> Html
view channels model =
  let {sidebarHeader, sidebarBody, sidebarFooter} = case model.viewMode of
    OpenMenuMode  -> {
      sidebarHeader = lazy viewOpenMenuHeader channels.update,
      sidebarBody   = lazy2 OpenMenu.view model.docs model.currentDoc,
      sidebarFooter = viewOpenMenuFooter
    }

    CurrentDocMode -> {
      sidebarHeader = lazy2 viewCurrentDocHeader model.currentDoc channels,
      sidebarBody   = lazy CurrentDoc.view model.currentDoc,
      sidebarFooter = lazy viewCurrentDocFooter channels
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

viewCurrentDocFooter : Channels -> Html
viewCurrentDocFooter channels =
  div [id "left-sidebar-footer", class "sidebar-footer"] [
    span [id "add-chapter",
      title "Add Chapter",
      onClick <| send channels.newChapter (),
      class "flaticon-plus81"] []]

viewOpenMenuHeader updateChannel =
  div [key "open-menu-header", id sidebarHeaderId, class sidebarHeaderClass] [
    span [class "sidebar-header-control",
      onClick <| send updateChannel (SetViewMode CurrentDocMode)] [text "cancel"]
  ]

viewCurrentDocHeader : Doc -> Channels -> Html
viewCurrentDocHeader currentDoc channels =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    menu [id sidebarHeaderId, class sidebarHeaderClass] [
      menuitem [
        title "New",
        class "sidebar-header-control flaticon-add26",
        onClick <| send channels.newDoc ()] [],
      menuitem [
        title "Open",
        class "sidebar-header-control flaticon-folder63",
        onClick <| send channels.update (SetViewMode OpenMenuMode)] [],
      menuitem [
        title "Download",
        class "sidebar-header-control flaticon-cloud134",
        onClick <| send channels.download downloadOptions] [],
      menuitem [
        title "Print",
        class "sidebar-header-control flaticon-printer70",
        onClick <| send channels.print ()] [],
      menuitem [
        title "Settings",
        class "sidebar-header-control flaticon-gear33"] []
    ]