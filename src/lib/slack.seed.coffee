request = require "requestretry"

DEFAULT_TIMEOUT = 10 * 1000
DEFAULT_MAX_ATTEMPTS = 3

class Slack
  constructor: (@token, @domain) ->
    @apiMode = not @domain?
    @url = @composeUrl()
    @timeout = DEFAULT_TIMEOUT
    @maxAttempts = DEFAULT_MAX_ATTEMPTS

  composeUrl: =>
    return "https://slack.com/api/"

  setWebhook: (url) =>
    @webhookUrl = url
    return this

  detectEmoji: (emoji) =>
    obj = {}

    unless emoji
      obj.key = "icon_emoji"
      obj.val = ""
      return obj

    obj.key = if emoji.match(/^http/) then "icon_url" else "icon_emoji"
    obj.val = emoji
    return obj

  webhook: (options, callback) =>

    emoji = @detectEmoji(options.icon_emoji)

    payload =
      channel: options.channel
      text: options.text
      username: options.username
      attachments: options.attachments

    payload[emoji.key] = emoji.val

    request
      method: "POST"
      url: @webhookUrl
      body: JSON.stringify payload
      timeout: @timeout
      maxAttempts: @maxAttempts
      retryDelay: 0
    , (err, body, response) ->
      if err? then return callback(err)
      callback null, {
        status: if err or response isnt "ok" then "fail" else "ok"
        statusCode: body.statusCode
        headers: body.headers
        response: response
      }

  api: (method, options = {}, callback) =>

    if typeof options is "function"
      callback = options
      options = {}

    options.token = @token

    url = @url + method

    request_arg = { 
      url: @url + method 
      timeout: @timeout
      maxAttempts: @maxAttempts
      retryDelay: 0
    }

    if @_is_post_api(method)
      request_arg.method = "POST"
      request_arg.form = options
    else
      request_arg.method = "GET"
      request_arg.qs = options

    request request_arg, (err, body, response) ->
      if err
        return callback(err,
          status: "fail"
          response: response
        )

      try
        ret = JSON.parse(response)
      catch
        return callback(new Error("Invalid server response"),
          status: "fail"
          response: response
        )
      return callback?(err, ret)

    return this

  _is_post_api: (method) ->
    method is "files.upload"

module.exports = Slack
