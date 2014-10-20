blankDocHtml = require("./templates/BlankDocBody.mustache")()
introDocHtml = require("./templates/IntroDocBody.mustache")()

htmlUntil = (node, predicate) ->
  if predicate node
    (node?.innerHTML ? "") + (htmlUntil node.nextSibling, predicate)
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
      words:            0 # TODO infer from html
      creationTime:     now
      lastModifiedTime: now
      html:             html
    }

docFromHtml = (html) ->
  wrapperNode = document.createElement "div"
  wrapperNode.innerHTML = html

  {
    title:       inferTitleFrom(wrapperNode) ? ""
    description: inferDescriptionFrom(wrapperNode) ? ""
    chapters:    inferChaptersFrom(wrapperNode)
    words:       0 # TODO infer from summed chapters, title, and description
  }

docFromFile = (filename, lastModifiedTime, html) ->
  doc = docFromHtml html

  doc.title = filename
  doc.lastModifiedTime = doc.creationTime = lastModifiedTime

  for chapter in doc.chapters
    chapter.lastModifiedTime = chapter.creationTime = lastModifiedTime

  doc

module.exports = {
  blankDocHtml
  introDocHtml
  inferTitleFrom
  inferChaptersFrom
  docFromHtml
  docFromFile
}
