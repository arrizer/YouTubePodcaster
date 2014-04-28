# YouTube Podcaster

Make video podcasts out of youtube channels.

## Installation

You need nodejs, coffee-script, memcached and [youtube-dl](https://github.com/Homebrew/homebrew/commits/master/Library/Formula/youtube-dl.rb) installed on your server.

If you have all prerequesites, checkout this repository and run `npm install` to install some dependencies.

Then run the server with `coffee app.coffee` or your favourite nodejs deployment manager.

## Usage

You need the YouTube channel ID to subscribe to a video podcast. The last part of the youtube channel homepage URL is the channel ID, for example`https://www.youtube.com/channel/UC3LqW4ijMoENQ2Wv17ZrFJA` for the "PBS Idea Channel".

The video podcast URL is then:
`http://yourdomain.com/channel/<channelid>`

Each enclosure in the feed links to your server, e.g. `http://yourdomain.com/channel/<videoid>`. This URL resolves a deep-link to the video file within the YouTube CDN and redirect the Podcatcher there.