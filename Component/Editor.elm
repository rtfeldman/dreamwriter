module Component.Editor where

import Dreamwriter (..)

import String
import Html (..)
import Html.Attributes (..)
import Html.Lazy (..)
import Html.Events (..)
import Maybe
import List (..)
import LocalChannel (send, LocalChannel)
import Signal
import Json.Encode (string)

type alias Channels a = { a |
  fullscreen  : LocalChannel FullscreenState,
  syncState   : LocalChannel SyncState,
  remoteSync  : LocalChannel (),
  execCommand : LocalChannel String
}

type alias Model = {
  currentDoc  : Doc,
  syncState   : SyncState,
  fullscreen  : FullscreenState
}

initialModel : Model
initialModel = {
    currentDoc  = emptyDoc,
    syncState   = Initializing,
    fullscreen  = False
  }

view : Channels a -> Model -> Html
view channels model =
  lazy2 viewEditor channels model

viewEditor : Channels a -> Model -> Html
viewEditor channels model =
  div [id "editor-container"] [
    div [id "editor-frame"] [
      div [id "editor-header"] [
        div [class "toolbar-section toolbar-button flaticon-zoom19"] [],
        div [class "toolbar-section"] [
          viewFontControl channels.execCommand "toggle-bold" "B" "bold",
          viewFontControl channels.execCommand "toggle-italics" "I" "italic",
          viewFontControl channels.execCommand "toggle-strikethrough" "\xA0S\xA0" "strikethrough"
        ],
        lazy2 viewFullscreenButton channels.fullscreen model.fullscreen
      ],

      div [id "document-page"] <| [
        h1  [id "edit-title"      ] [],
        div [id "edit-description"] []
      ] ++ concatMap (lazyViewChapter << .id) model.currentDoc.chapters,

      viewFooter channels.remoteSync model.currentDoc model.syncState
    ]
  ]

viewFooter : LocalChannel () -> Doc -> SyncState -> Html
viewFooter remoteSyncChannel doc syncState =
  let display  = renderSyncInput remoteSyncChannel
      children = case syncState of
        Initializing        -> -- We're reconnecting; don't display anything yet.
          [
            viewWordCount doc
          ]
        Disconnected        -> -- We aren't authenticated, so we can't sync.
          [
            viewWordCount doc,
            display False " sync to Dropbox"
          ]
        Connected name      -> -- We're authenticated and can sync to Dropbox.
          [
            viewWordCount doc,
            display True  (" syncing to " ++ name ++ "’s Dropbox")
          ]
        PromptingConnect    -> -- Prompt the user to authenticate via OAuth.
          [
            a    [href "javascript:;"] [text "Sign in to Dropbox"],
            a    [href "https://db.tt/dHLm7rHU", target "_blank"] [text "Create a free Dropbox Account"],
            span [] [text "Cancel"]
          ]
        PromptingDisconnect -> -- Confirm that the user wants to disconnect.
          [
            a    [href "javascript:;"] [text "Sign Out of Dropbox"],
            span [] [text "Cancel"]
          ]
  in
    div [id "editor-footer"] children

viewWordCount : Doc -> Html
viewWordCount doc =
  let wordCount = doc.titleWords + doc.descriptionWords +
    (sum <| map (\chap -> chap.headingWords + chap.bodyWords) doc.chapters)
  in
    div [id "doc-word-count"] [text <| (pluralize "word" wordCount) ++ " saved"]

renderSyncInput : LocalChannel () -> Bool -> String -> Html
renderSyncInput remoteSyncChannel syncing syncText =
  div [id "dropbox-sync"] [
    input [
      id "toggle-dropbox-sync",
      property "type" (string "checkbox"),
      checked syncing,
      onClick <| send remoteSyncChannel ()
    ] [],
    label [for "toggle-dropbox-sync"] [text syncText]
  ]

withCommas : Int -> String
withCommas num =
  if num >= 1000
    then
      let prefix = withCommas <| floor (num / 1000)
      in
        prefix ++ "," ++ (String.right 3 <| toString num)
    else
      toString num

pluralize : String -> Int -> String
pluralize noun quantity =
  if quantity == 1
    then "1 " ++ noun
    else (withCommas quantity) ++ " " ++ noun ++ "s"

viewFullscreenButton : LocalChannel FullscreenState -> FullscreenState -> Html
viewFullscreenButton fullscreenChannel fullscreen =
  let {fullscreenClass, targetMode, fullscreenTitle} = case fullscreen of
    True ->
      { fullscreenClass = "flaticon-collapsing"
      , targetMode      = False
      , fullscreenTitle = "Leave Fullscreen Mode"
      }
    False ->
      { fullscreenClass = "flaticon-expand"
      , targetMode      = True
      , fullscreenTitle = "Enter Fullscreen Mode"
      }
  in
    div [class ("toolbar-section toolbar-button " ++ fullscreenClass),
      title fullscreenTitle,
      onClick <| send fullscreenChannel targetMode
    ] []

onCheck : (Bool -> Signal.Message) -> Attribute
onCheck =
    on "change" targetChecked

lazyViewChapter : Identifier -> List Html
lazyViewChapter chapterId = [
    lazy viewChapterHeading chapterId,
    lazy viewChapterBody    chapterId
  ]

viewChapterBody : Identifier -> Html
viewChapterBody chapterId =
  div [key ("chapter-body-" ++ chapterId),
    id ("edit-chapter-body-" ++ chapterId),
    class "chapter-body"] []

viewChapterHeading : Identifier -> Html
viewChapterHeading chapterId =
  h2 [key ("chapter-heading-" ++ chapterId),
    id ("edit-chapter-heading-" ++ chapterId),
    class "chapter-heading"] []

viewFontControl : LocalChannel String -> String -> String -> String -> Html
viewFontControl execCommandChannel idAttr label command =
  span [class "font-control toolbar-button toolbar-font-button", id idAttr,
    (property "unselectable" (string "on")),
    onClick <| send execCommandChannel command] [text label]