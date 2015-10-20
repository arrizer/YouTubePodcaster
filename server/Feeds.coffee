AppKit  = require 'appkit'
Cache   = require './Cache'
YouTube = require './YouTube'
Podcast = require 'podcast'
Async   = require 'async'

module.exports = class Feeds extends AppKit.ServerModule
  constructor: ->
    super
    @youtube = new YouTube(@server.config.google_api_key)
    @cache = Cache.Local()
  
  mount: ->
    @router.get '/channel/:channelid', (req,res) =>
      @youtube.channel req.params.channelid, (error, channel) =>
        if error?
          res.status(500).send error.toString()
        else if channel.items.length == 0
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
          @youtube.channelVideos req.params.channelid, (error, videos) =>
            if error?
              res.status(500).send error
            else
              count = 0
              for video in videos.items
                feed.item
                  title: video.snippet.title
                  description: video.snippet.description
                  url: 'https://@youtube.com/watch?v='+video.snippet.resourceId.videoId
                  guid: video.id
                  date: video.snippet.publishedAt
                  enclosure:
                    url: @server.config.domain + 'video/' + video.snippet.resourceId.videoId + '.mp4'
                    mime: 'video/mp4'
              res.type 'application/rss+xml; charset=utf-8'
              res.send feed.xml('  ')
                
    @router.get '/video/:videoid.mp4', (req,res) =>
      @youtube.videoFileURL req.params.videoid, (error, url) =>
        res.redirect url