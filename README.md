# YouTube Podcaster

Make video podcasts out of youtube channels.

## Installation

You need nodejs, coffee-script, memcached and [youtube-dl](https://github.com/Homebrew/homebrew/commits/master/Library/Formula/youtube-dl.rb) installed on your server.

If you have all prerequesites, checkout this repository and run `npm install` to install some dependencies.

Then run the server with `coffee app.coffee` or your favourite nodejs deployment manager.

## Usage

### Subscribe to Channels

You need the YouTube channel ID to subscribe. The last part of the youtube channel homepage URL is the channel ID, for example `https://www.youtube.com/channel/UC3LqW4ijMoENQ2Wv17ZrFJA` for the "PBS Idea Channel".

The channel video podcast URL is then:
`http://yourdomain.com/channel/<channelid>`

### Subscribe to Playlists

You need the YouTube playlist ID to subscribe. The parameter is named `list` in the URL to the playlists contents, for example `https://www.youtube.com/playlist?list=PL8dPuuaLjXtPAJr1ysd5yGIyiSFuh0mIL` for the "Crash Course: Astronomy" playlist of the "Crash Course" channel.

The playlist video podcast URL is then:
`http://yourdomain.com/channel/<playlistid>`

## Video Links

Each enclosure in the feed links to your server, e.g. `http://yourdomain.com/channel/<videoid>`. This URL resolves a deep-link to the video file within the YouTube CDN and redirects the Podcatcher there. Your Podcatcher must support HTTP redirects when playing a video for this to work!