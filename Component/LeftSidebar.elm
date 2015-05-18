module Component.LeftSidebar where

import Dreamwriter exposing exposing (..)

import Component.LeftSidebar.OpenMenuView as OpenMenu
import Component.LeftSidebar.CurrentDocView as CurrentDoc

import Html exposing exposing (..)
import Html.Attributes exposing exposing (..)
import Html.Events exposing exposing (..)
import Html.Lazy exposing exposing (..)
import Maybe
import Regex exposing exposing (..)
import LocalChannel exposing (send, LocalChannel)

type ViewMode = CurrentDocMode | OpenMenuMode | SettingsMode

type alias Channels a = { a |
  print               : LocalChannel (),
  newDoc              : LocalChannel (),
  newChapter          : LocalChannel (),
  openFromFile        : LocalChannel (),
  navigateToTitle     : LocalChannel (),
  navigateToChapterId : LocalChannel Identifier,
  download            : LocalChannel DownloadOptions,
  update              : LocalChannel Update
}

type alias Model = {
  viewMode     : ViewMode,
  docs         : List Doc,
  currentDocId : Maybe Identifier,
  currentDoc   : Doc
}

initialModel : Model
initialModel = {
    viewMode     = CurrentDocMode,
    docs         = [],
    currentDocId = Nothing,
    currentDoc   = emptyDoc
  }

type Update
  = NoOp
  | SetViewMode ViewMode
  | OpenDocId Identifier

transition : Update -> Model -> Model
transition update model =
  case update of
    NoOp -> model

    SetViewMode mode -> { model | viewMode <- mode }

    OpenDocId id -> { model |
      currentDocId <- Just id,
      viewMode     <- CurrentDocMode
    }

-- Replace illegal filename characters with underscores
illegalFilenameCharMatcher = regex "[/\\<>?|\":*]"

legalizeFilename : String -> String
legalizeFilename = replace All illegalFilenameCharMatcher (\_ -> "_")

downloadContentType = "text/plain;charset=UTF-8"

view : Channels a -> Model -> Html
view channels model =
  let {sidebarHeader, sidebarBody, sidebarFooter} = case model.viewMode of
    OpenMenuMode  -> {
      sidebarHeader = lazy viewOpenMenuHeader channels.update,
      sidebarBody   = lazy2 (OpenMenu.view channels.openFromFile (\id -> send channels.update (OpenDocId id))) model.docs model.currentDoc,
      sidebarFooter = viewOpenMenuFooter
    }

    CurrentDocMode -> {
      sidebarHeader = lazy2 viewCurrentDocHeader model.currentDoc channels,
      sidebarBody   = lazy3 CurrentDoc.view channels.navigateToTitle channels.navigateToChapterId model.currentDoc,
      sidebarFooter = lazy  viewCurrentDocFooter channels
    }

    SettingsMode  -> { -- TODO make this different than CurrentDocMode
      sidebarHeader = lazy2 viewCurrentDocHeader model.currentDoc channels,
      sidebarBody   = lazy3 CurrentDoc.view channels.navigateToTitle channels.navigateToChapterId model.currentDoc,
      sidebarFooter = lazy  viewCurrentDocFooter channels
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

viewCurrentDocFooter : Channels a -> Html
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

viewCurrentDocHeader : Doc -> Channels a -> Html
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
        class "sidebar-header-control flaticon-gear33",
        onClick <| send channels.update (SetViewMode SettingsMode)] []
    ]