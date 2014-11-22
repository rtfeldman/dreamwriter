# DreamBox: Dreamwriter Dropbox integration

dropboxApiKey = 'x1aqcubgani7y5s'

# Wraps Dropbox.Client with Dreamwriter-specific
# error handling and the like.
module.exports = class DreamBox
  @auth: ->
    new Promise (resolve, reject) ->
      client = new Dropbox.Client key: dropboxApiKey

      client.authenticate (error, client) ->
        if error
          reject (translateError error)
        else
          resolve (new DreamBox client)

  # This should only be instantiated with an
  # authenticated Dropbox.Client instance
  constructor: (@client) ->

  writeFile: (filename, content, callback) =>
    @client.writeFile filename, content, (error, stat) ->
      errorMessage = if error
        translateError error
      else
        null

      callback errorMessage, stat

translateError = (error) ->
  switch error.status
    when Dropbox.ApiError.INVALID_TOKEN 
      "Your session has timed out. Please disconnect Dreamwriter from Dropbox and reconnect."
    when Dropbox.ApiError.NOT_FOUND
      "The requested file of folder was not found in your Dropbox."
    when Dropbox.ApiError.OVER_QUOTA
      "You have exceeded your Dropbox quota!"
    when Dropbox.ApiError.RATE_LIMITED
      "Dreamwriter has made too many Dropbox API requests...please try again later."
    when Dropbox.ApiError.NETWORK_ERROR
      # An error occurred at the XMLHttpRequest layer.
      # Most likely, the user's network connection is down.
      # API calls will not succeed until the user gets back online.
      "Network Error - are you still connected to the Internet?"
    when Dropbox.ApiError.INVALID_PARAM
      "Invalid parameter - please try refereshing the page"
    when Dropbox.ApiError.OAUTH_ERROR
      "OAuth Error - please try refereshing the page"
    when Dropbox.ApiError.INVALID_METHOD
      "Invalid Method - please try refereshing the page"
    else
      "Unknown Method"