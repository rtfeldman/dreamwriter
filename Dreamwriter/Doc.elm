module Dreamwriter.Doc (Doc, Chapter, newDoc, newChapter, updateDoc) where

import Dreamwriter (Identifier, newIdentifier)
import Maybe
import String

type Doc =
  { id          : Identifier
  , title       : String
  , chapters    : [Chapter]
  }

type Chapter =
  { heading     : String
  }

newDoc : String -> [Chapter] -> Doc
newDoc title chapters =
  { id       = newIdentifier
  , title    = title
  , chapters = chapters
  }

newChapter : String -> Chapter
newChapter heading =
  { heading = heading
  }

updateHeading : String -> Chapter -> Chapter
updateHeading heading chapter = {chapter | heading <- heading}

updateDoc : String -> [String] -> Doc -> Doc
updateDoc title chapterHeadings doc =
  {doc | title <- title,
   chapters <- zipWith updateHeading chapterHeadings doc.chapters
  }

{-| Need to get all this working later
-- Ports --

-- FIXME need to get this via a port
type HtmlNode = {}

-- FIXME should be a port
createElement : String -> HtmlNode
createElement tag = {}

-- FIXME should be a port
setInnerHTML : HtmlNode -> String -> HtmlNode
setInnerHTML node html = {}

-- FIXME should be a port
getFirstChild : HtmlNode -> Maybe HtmlNode
getFirstChild node = Just {}

-- FIXME should be a port
querySelectorAll : HtmlNode -> String -> [HtmlNode]
querySelectorAll node queryStr = [{}]

fromHtmlDoc : HtmlNode -> Doc
fromHtmlDoc htmlDoc =
  let title    = titleFromNode htmlDoc
      chapters = chaptersFromNode htmlDoc
  in
    newDoc title chapters

fromHtmlStr : String -> Doc
fromHtmlStr = fromHtmlDoc << htmlStrToHtmlDoc

htmlStrToHtmlDoc : String -> HtmlNode
htmlStrToHtmlDoc html =
  let docElem = createElement "div"
  in
    getFirstChild |> setInnerHTML docElem ("<div id='loaded-content'>" ++ html ++ "</div>")

titleFromNode : HtmlNode -> String
titleFromNode node =
  let titleElems  = querySelectorAll node "h1"
      textContent = if (length titleElems) > 0
        then (head titleElems).textContent
        else ""
  in
    String.trim textContent

chapterFromNode : HtmlNode -> Chapter
chapterFromNode node = newChapter |> String.trim node.textContent

chaptersFromNode : HtmlNode -> [Chapter]
chaptersFromNode node = map chapterFromNode (querySelectorAll node "h2")

wrapInDocumentMarkup : String -> String
wrapInDocumentMarkup bodyHtml = """
    <html>
      <head>
        <meta charset="utf-8"/>
        <meta name="generator" content="http://dreamwriter.io"/>
        <style type="text/css">
            @page {
                margin: 0.8cm;
            }

            ::selection {
                background: #e0e0e0;
                color: inherit;
                text-shadow: inherit;
            }

            ::-moz-selection {
                background: #e0e0e0;
                color: inherit;
                text-shadow: inherit;
            }

            .note-highlight {
                background-color: #c0c0c0;
            }

            body {
                font-size: 12px;
                color: black;
                font-family: Georgia, PT Serif, Times New Roman, serif;
                overflow-x: visible;
                width: 42em;
                padding: 6em 1.5em 6em 1.5em;
                margin-left: auto;
                margin-right: auto;
                word-wrap: break-word;
            }

            h1, h2, h3, h4 {
                font-weight: normal;
                font-family: inherit;
                text-align: center;
                margin: 0;
                line-height: 1.1em;
            }

            h1 {
                margin-bottom: 24px;
                font-size: 48px;
            }

            h2 {
                font-size: 36px;
                margin-top: 36px;
                margin-bottom: 36px;
                page-break-before: always;
            }

            h3 {
                font-size: 24px;
                margin-bottom: 96px;
                line-height: 1.5em;
            }

            p, div {
                font-family: inherit;
                text-indent: 30px;
                margin: 0;
                line-height: 1.5em;
                font-size: 18px;
            }

            p > *, div > * {
                text-indent: 0;
            }

            hr {
                width: 20%;
                margin-top: 24px;
                margin-bottom: 24px;
                margin-left: auto;
                margin-right: auto;
                background-color: black;
            }

            blockquote {
                margin-left: 1em;
                page-break-inside: avoid;
            }
        </style>
      </head>
      <body>""" ++ bodyHtml ++ """</body>
    </html>
  """

--fromFile : String -> Date -> String -> Doc
--fromFile fileName lastModified html =
--  _.defaults DreamDoc.fromHtmlStr(html), 
--    title: fileName.replace(/.html$/, '').replace('_', ' ')

-}