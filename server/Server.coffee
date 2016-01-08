AppKit = require 'appkit'
Feeds  = require './Feeds'

module.exports = class Server extends AppKit.Server
  init: (next) ->
    @loadModule new Feeds(@)
    next()