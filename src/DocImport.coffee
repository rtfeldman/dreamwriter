blankDocHtml = require("./templates/BlankDocBody.mustache")()
introDocHtml = require("./templates/IntroDocBody.mustache")()

inferTitleFrom = (node) ->
  node.querySelector("h1")?.textContent

inferChaptersFrom = (node) ->
  for heading in node.querySelectorAll("h2")
    {heading: heading.textContent}

docFromHtml = (html) ->
  wrapperNode = document.createElement "div"
  wrapperNode.innerHTML = html

  {
    title:    inferTitleFrom(wrapperNode) ? ""
    chapters: inferChaptersFrom(wrapperNode)
  }

docFromFile = (filename, lastModifiedTime, html) ->
  doc = docFromHtml html

  doc.title = filename
  doc.lastModifiedTime = lastModifiedTime

  doc

module.exports = {
  blankDocHtml
  introDocHtml
  inferTitleFrom
  inferChaptersFrom
  docFromHtml
  docFromFile
}
