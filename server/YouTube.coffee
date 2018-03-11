HTTP      = require 'https'
Log       = require('appkit').Log
URL       = require 'url'
Async     = require 'async'
Cache     = require './Cache'
ChildProcess = require 'child_process'

log = Log.Module('YouTube')

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
    @apiRequestCached 'channels', parameters, yes, 60*5, next
  
  channelVideos: (channelID, next) ->
    parameters = 
      part: 'contentDetails'
      id: channelID
    @apiRequestCached 'channels', parameters, yes, 60*5, (error, result) =>
      return next(error) if error?
      return next(new Error("Channel not found")) unless result.items.length > 0
      channel = result.items[0]
      @playlistVideos channel.contentDetails.relatedPlaylists.uploads, next
      
  playlist: (playlistID, next) ->
    parameters = 
      part: 'snippet'
      id: playlistID
    @apiRequestCached 'playlists', parameters, yes, 60*60, next
        
  playlistVideos: (playlistID, next) ->
    parameters = 
      part: 'id,snippet,status,contentDetails'
      id: playlistID
    @apiRequestCached 'playlists', parameters, no, 60*5, (error, result) =>
      return next(error) if error?
      return next(new Error("Playlist #{playlistID} of channel not found")) unless result.items.length > 0        
      playlist = result.items[0]
      #console.log result.pageInfo
      parameters = 
        part: 'id,snippet,contentDetails,status'
        playlistId: playlist.id
        maxResults: 50
      @apiRequestCached 'playlistItems', parameters, yes, 60*5, next

  preCacheVideoURLs: (videoIDs) ->
    Async.eachLimit videoIDs, 10, (videoID, done) =>
      log.debug "Caching video URL for #{videoID}"
      @videoFileURL videoID, (error, url) ->
        done()
    , ->
      log.debug "Finished caching"
    
  videoFileURL: (videoID, next) ->
    cache.cache
      key: 'ytvideoresolve:'+videoID
      lifetime: (5 * 60 * 60)
      allow: yes
      fetch: (store) =>
        cmd = 'youtube-dl -g -f best "http://youtube.com/watch?v='+videoID+'"'
        log.debug '$ %s', cmd
        ChildProcess.exec cmd, (error, stdout, stderr) =>
          if stderr? and stderr isnt ''
            log.error stderr
            next(stderr)
          else
            url = stdout.replace "\n", ""
            log.debug 'Resolved URL = %s', url
            store(url)
      get: (url, cached) =>
        next null, url, cached
