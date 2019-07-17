AppKit  = require 'appkit'
Cache   = require './Cache'
YouTube = require './YouTube'
Podcast = require 'podcast'
Async   = require 'async'

module.exports = class Feeds extends AppKit.MountedServerModule
  constructor: ->
    super
    @youtube = new YouTube(@server.config.google_api_key)
    @cache = Cache.Local()
  
  mount: ->
    @router.get '/channel/:channelid', (req,res) =>
      channelID = req.params.channelid
      @log.info "Requesting channel with id '#{channelID}'..."
      @youtube.channel channelID, (error, channel) =>
        if error?
          @log.error "Channel #{channelID} could not be fetched: #{error}"
          res.status(500).send error.toString()
        else if channel.items.length == 0
          @log.error "Channel #{channelID} not found"
          res.status(404).send 'Channel not found'
        else
          channel = channel.items[0].snippet
          feed = new Podcast
            title: channel.title
            description: channel.description
            image_url: channel.thumbnails.high.url
            feed_url: @server.config.domain + req.url
            site_url: @server.config.domain
            ttl: 10
            generator: 'YouTube Podcaster'
            itunesSummary: channel.description
            itunesImage: channel.thumbnails.high.url
          @log.info "Fetching videos in channel #{channelID}"
          @youtube.channelVideos channelID, (error, videos) =>
            if error?
              @log.error "Failed to fetch channel videos for channel #{channelID}: #{error}"
              res.status(500).send error
            else
              videoURLs = []
              count = 0
              @log.info "Responding with #{videos.items.length} videos in channel #{channelID}"
              for video in videos.items
                videoURLs.push(video.snippet.resourceId.videoId)
                feed.item
                  title: video.snippet.title
                  description: video.snippet.description
                  url: 'https://@youtube.com/watch?v='+video.snippet.resourceId.videoId
                  guid: video.id
                  date: video.snippet.publishedAt
                  enclosure:
                    url: @server.config.domain + 'video/' + video.snippet.resourceId.videoId + '.mp4'
                    mime: 'video/mp4'
              #@youtube.preCacheVideoURLs(videoURLs)
              res.type 'application/rss+xml; charset=utf-8'
              res.send feed.xml('  ')
    
    @router.get '/playlist/:playlistid', (req,res) =>
      playlistID = req.params.playlistid
      @log.info "Requesting playlist with id '#{playlistID}'..."
      @youtube.playlist playlistID, (error, playlist) =>
        if error?
          @log.info "Failed to fetch playlist with id '#{playlistID}': #{error}"
          res.status(500).send error.toString()
        else if playlist.items.length == 0
          @log.info "Playlist with id '#{playlistID}' not found"
          res.status(404).send 'Playlist not found'
        else
          playlist = playlist.items[0].snippet
          @log.info "Requesting channel for playlist with channel id '#{playlist.channelId}'..."
          @youtube.channel playlist.channelId, (error, channel) =>
            if error?
              @log.error "Channel #{channelID} could not be fetched: #{error}"
              res.status(500).send error.toString()
            else if channel.items.length == 0
              @log.error "Channel #{channelID} not found"
              res.status(404).send 'Channel not found'
            else
              channel = channel.items[0].snippet
              feed = new Podcast
                title: channel.title + ': ' + playlist.title
                description: playlist.description
                image_url: playlist.thumbnails.high.url
                feed_url: @server.config.domain + req.url
                site_url: @server.config.domain
                ttl: 10
                generator: 'YouTube Podcaster'
                itunesSummary: playlist.description
                itunesImage: playlist.thumbnails.high.url
              @log.info "Requesting videos in playlist with id '#{playlistID}'..."
              @youtube.playlistVideos playlistID, (error, videos) =>
                if error?
                  res.status(500).send error
                else
                  videoURLs = []
                  count = 0
                  @log.info "Responding with #{videos.items.length} videos in playlist with id '#{playlistID}'..."
                  for video in videos.items
                    videoURLs.push(video.snippet.resourceId.videoId)
                    feed.item
                      title: video.snippet.title
                      description: video.snippet.description
                      url: 'https://@youtube.com/watch?v='+video.snippet.resourceId.videoId
                      guid: video.id
                      date: video.snippet.publishedAt
                      enclosure:
                        url: @server.config.domain + 'video/' + video.snippet.resourceId.videoId + '.mp4'
                        mime: 'video/mp4'
                  #@youtube.preCacheVideoURLs(videoURLs)
                  res.type 'application/rss+xml; charset=utf-8'
                  res.send feed.xml('  ')
                
    @router.get '/video/:videoid.mp4', (req,res) =>
      videoID = req.params.videoid
      @log.info "Resolving video deeplink for video with ID '#{videoID}'"
      @youtube.videoFileURL videoID, (error, url) =>
        if error?
          @log.error "Failed to resolve video deeplink for video with ID '#{videoID}': #{error}"
          res.status(400).send 'Could not reslve video URL'
        else
          @log.debug "Video deeplink for '#{videoID}' is: #{url}"
          res.redirect url