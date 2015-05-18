module Component.LeftSidebar where

import Dreamwriter exposing (..)

import Component.LeftSidebar.OpenMenuView as OpenMenu
import Component.LeftSidebar.CurrentDocView as CurrentDoc

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Maybe
import Regex exposing (..)
import Signal exposing (Address)

type ViewMode = CurrentDocMode | OpenMenuMode | SettingsMode

type Action
  = NoAction
  | NewDoc
  | OpenFromFile
  | NavigateToTitle
  | NavigateToChapterId Identifier
  | Download DownloadOptions
  | NewChapter
  | Print
  | UpdateModel ModelUpdate

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

type ModelUpdate
  = NoOp
  | SetViewMode ViewMode
  | OpenDocId Identifier

applyAction : Action -> Model -> Model
applyAction action model =
  case action of
    UpdateModel update -> transition update model
    _                  -> model

transition : ModelUpdate -> Model -> Model
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

view : Address Action -> Model -> Html
view actions model =
  let forward = Signal.forwardTo actions

      newChapter          = forward (always NewChapter)
      navigateToTitle     = forward (always NavigateToTitle)
      openFromFile        = forward (always OpenFromFile)
      openDoc             = forward (UpdateModel << OpenDocId)
      navigateToChapterId = forward NavigateToChapterId
      updateModel         = forward UpdateModel

      {sidebarHeader, sidebarBody, sidebarFooter} =
        case model.viewMode of
          OpenMenuMode  -> {
            sidebarHeader = lazy viewOpenMenuHeader updateModel,
            sidebarBody   = lazy2 (OpenMenu.view openFromFile openDoc) model.docs model.currentDoc,
            sidebarFooter = viewOpenMenuFooter
          }

          CurrentDocMode -> {
            sidebarHeader = lazy2 viewCurrentDocHeader model.currentDoc actions,
            sidebarBody   = lazy3 CurrentDoc.view navigateToTitle navigateToChapterId model.currentDoc,
            sidebarFooter = lazy  viewCurrentDocFooter newChapter
          }

          SettingsMode  -> { -- TODO make this different than CurrentDocMode
            sidebarHeader = lazy2 viewCurrentDocHeader model.currentDoc actions,
            sidebarBody   = lazy3 CurrentDoc.view navigateToTitle navigateToChapterId model.currentDoc,
            sidebarFooter = lazy  viewCurrentDocFooter newChapter
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

viewCurrentDocFooter : Address () -> Html
viewCurrentDocFooter newChapter =
  div [id "left-sidebar-footer", class "sidebar-footer"] [
    span [id "add-chapter",
      title "Add Chapter",
      onClick newChapter (),
      class "flaticon-plus81"] []]

viewOpenMenuHeader : Address ModelUpdate -> Html
viewOpenMenuHeader updateModel =
  div [key "open-menu-header", id sidebarHeaderId, class sidebarHeaderClass] [
    span [class "sidebar-header-control",
      onClick updateModel (SetViewMode CurrentDocMode)] [text "cancel"]
  ]

viewCurrentDocHeader : Doc -> Address Action -> Html
viewCurrentDocHeader currentDoc actions =
  let downloadOptions = {
    filename    = (legalizeFilename currentDoc.title) ++ ".html",
    contentType = downloadContentType
  }
  in
    menu [id sidebarHeaderId, class sidebarHeaderClass] [
      menuitem [
        title "New",
        class "sidebar-header-control flaticon-add26",
        onClick actions NewDoc] [],
      menuitem [
        title "Open",
        class "sidebar-header-control flaticon-folder63",
        onClick actions (UpdateModel <| SetViewMode OpenMenuMode)] [],
      menuitem [
        title "Download",
        class "sidebar-header-control flaticon-cloud134",
        onClick actions (Download downloadOptions)] [],
      menuitem [
        title "Print",
        class "sidebar-header-control flaticon-printer70",
        onClick actions Print] [],
      menuitem [
        title "Settings",
        class "sidebar-header-control flaticon-gear33",
        onClick actions (UpdateModel <| SetViewMode SettingsMode)] []
    ]