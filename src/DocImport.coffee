wrapInDoc    =                 require("./templates/Doc.mustache")
blankDocHtml = wrapInDoc body: require("./templates/BlankDocBody.mustache")()
introDocHtml = wrapInDoc body: require("./templates/IntroDocBody.mustache")()

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

module.exports = {
  blankDocHtml
  introDocHtml
  inferTitleFrom
  inferChaptersFrom
  docFromHtml
}
