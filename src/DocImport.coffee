blankDocHtml        = require("./templates/BlankDocBody.mustache")()
introDocHtml        = require("./templates/IntroDocBody.mustache")()
blankChapterHtml    = require("./templates/BlankChapterBody.mustache")()
wrapInDocMarkup     = require("./templates/Doc.mustache")
countWords          = require("./WordCount.coffee")
blankChapterHeading = "Amazing Chapter"

htmlUntil = (node, predicate) ->
  if predicate node
    (node?.outerHTML ? "") + (htmlUntil node.nextSibling, predicate)
  else
    ""

inferTitleFrom = (node) ->
  node.querySelector("h1")?.textContent

inferDescriptionFrom = (node) ->
  "" # TODO grab everything between h1 and the first h2

inferChaptersFrom = (node) ->
  now = new Date().getTime()

  for heading in node.querySelectorAll("h2")
    html = htmlUntil heading.nextSibling, (node) ->
      node && (node.tagName != "H2") && !(node.querySelector? "h2")

    {
      heading:          heading.textContent
      headingWords:     0 # TODO infer from html
      bodyWords:        0 # TODO infer from html
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
