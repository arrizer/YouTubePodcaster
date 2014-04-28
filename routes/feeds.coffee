Cache = require '../classes/Cache'
YouTube = require '../classes/YouTube'
RSS = require 'rss'
Async = require 'async'

module.exports = (app) ->
  youtube = new YouTube(app.config.google_api_key)
  cache = Cache.Local()

  app.get '/channel/:channelid', (req,res) ->
    youtube.channel req.params.channelid, (error, channel) =>
      if error?
        res.status(500).send error.toString()
      else if channel.items.length == 0
        res.status(404).send 'Channel not found'
      else
        channel = channel.items[0].snippet
        feed = new RSS
          title: channel.title
          description: channel.description
          image_url: channel.thumbnails.high.url
          feed_url: app.config.domain
          site_url: app.config.domain
          ttl: 10
          generator: 'YouTube Podcaster'
        youtube.channelVideos req.params.channelid, (error, videos) =>
          if error?
            res.status(500).send error
          else
            count = 0
            for video in videos.items when video.contentDetails.upload?
              feed.item
                title: video.snippet.title
                description: video.snippet.description
                url: 'https://youtube.com/watch?v='+video.contentDetails.upload.videoId
                guid: video.id
                date: video.snippet.publishedAt
                enclosure:
                  url: app.config.domain + 'video/' + video.contentDetails.upload.videoId
            res.type 'application/rss+xml; charset=utf-8'
            res.send feed.xml('  ')
              
  app.get '/video/:videoid', (req,res) ->
    youtube.videoFileURL req.params.videoid, (error, url) =>
      res.redirect url