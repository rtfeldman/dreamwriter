blankDocHtml        = require("./templates/BlankDocBody.mustache")()
introDocHtml        = require("./templates/IntroDocBody.mustache")()
blankChapterHtml    = require("./templates/BlankChapterBody.mustache")()
wrapInDocMarkup     = require("./templates/Doc.mustache")
countWords          = require("./WordCount.coffee")
blankChapterHeading = "Amazing Chapter"

contentUntil = (node, predicate) ->
  if predicate node
    newHtml = node?.outerHTML   ? ""
    newText = node?.textContent ? ""

    {html, text} = contentUntil node.nextSibling, predicate

    {html: html + newHtml, text: text + newText}
  else
    {html: "", text: ""}

inferTitleFrom = (node) ->
  node.querySelector("h1")?.textContent

inferDescriptionFrom = (node) ->
  "" # TODO grab everything between h1 and the first h2

inferChaptersFrom = (node) ->
  now = new Date().getTime()

  for heading in node.querySelectorAll("h2")
    {html, text} = contentUntil heading.nextSibling, (node) ->
      node && (node.tagName != "H2") && !(node.querySelector? "h2")

    headingText = heading.textContent

    {
      heading:          headingText
      headingWords:     countWords(headingText)
      bodyWords:        countWords(text)
      creationTime:     now
      lastModifiedTime: now
      html:             html
    }

docFromHtml = (html) ->
  wrapperNode = document.createElement "div"
  wrapperNode.innerHTML = html

  title       = inferTitleFrom(wrapperNode) ? ""
  description = inferDescriptionFrom(wrapperNode) ? ""

  {
    title,
    description,
    chapters:         inferChaptersFrom(wrapperNode)
    titleWords:       countWords(title)
    descriptionWords: countWords(description)
  }

docFromFile = (filename, lastModifiedTime, html) ->
  doc = docFromHtml html

  doc.title ||= filename.replace(/\.[^\.]+$/, "") # Strip off file extension
  doc.lastModifiedTime = doc.creationTime = lastModifiedTime

  for chapter in doc.chapters
    chapter.lastModifiedTime = chapter.creationTime = lastModifiedTime

  doc

module.exports = {
  blankDocHtml
  introDocHtml
  blankChapterHtml
  blankChapterHeading
  inferTitleFrom
  inferChaptersFrom
  docFromHtml
  docFromFile
  wrapInDocMarkup
}
