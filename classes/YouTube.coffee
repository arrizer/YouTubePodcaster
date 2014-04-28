HTTP      = require 'https'
Log       = require './Log'
URL       = require 'url'
Cache     = require './Cache'
ChildProcess = require 'child_process'

log = Log.StdErr()

module.exports = class YouTube
  BASE = 'https://www.googleapis.com/youtube/v3/'
  cache = Cache.Local()
  
  constructor: (@apiKey) ->

  request: (url, next) ->
    log.debug 'GET %s', url
    req = HTTP.request url, (res) =>
      if res.statusCode is 200
        body = ''
        res.on 'data', (data) => 
          body += data.toString()
        res.on 'end', =>
          next null, body
      else
        error = new Error("Google API request to #{url} failed with HTTP error #{res.statusCode}")
        log.error '%s', error.toString()
        next error
    req.on 'error', (error) =>
      next error
    req.end()

  apiRequest: (endpoint, parameters, next) ->
    url = URL.parse(BASE + endpoint)
    parameters.key = @apiKey
    url.query = parameters
    url = URL.format(url)
    @request url, (error, data) =>
      if error?
        next error
      else
        json = JSON.parse(data)
        next null, json
        
  apiRequestCached: (endpoint, parameters, allowCache, lifetime, next) ->
    cache.cache
      key: 'ytapirequest:'+endpoint+':'+(key+':'+value for key,value of parameters).join(';')
      lifetime: lifetime
      allow: allowCache
      fetch: (store) =>
        @apiRequest endpoint, parameters, (error, result) =>
          if error?
            next error
          else
            store(result)
      get: (result, cached) =>
        next null, result, cached

  channel: (id, next) ->
    parameters = 
      part: 'id,snippet,contentDetails,statistics,topicDetails'
      id: id 
    @apiRequestCached 'channels', parameters, no, 60*60, next
  
  channelVideos: (channelID, next) ->
    parameters = 
      part: 'id, snippet, contentDetails'
      maxResults: 50
      channelId: channelID
    @apiRequestCached 'activities', parameters, no, 60*10, next
    
  videoFileURL: (videoID, next) ->
    cmd = 'youtube-dl -g "http://youtube.com/watch?v='+videoID+'"'
    log.debug '$ %s', cmd
    ChildProcess.exec cmd, (error, stdout, stderr) =>
      if stderr? and stderr isnt ''
        log.error stderr
        next(stderr)
      else
        next(null, stdout)