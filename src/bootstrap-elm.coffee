ports = {
  # headers: []
}

app = Elm.fullscreen Elm.App, ports

# Mutation observer does this - send over a list of chapter headings.
# app.ports.headers.send(["foo"]);

# switch iframeDocument.readyState
#   // "complete" in Chrome/Safari, "uninitialized" in Firefox
#   when "complete", "uninitialized"
#     try
#       iframeDocument.open()
#       iframeDocument.write html
#       iframeDocument.close()

#       onSuccess()
#     catch error
#       onError error
#   else
#     setTimeout (-> writeToIframeDocument iframeDocument, html, onSuccess, onError), 0