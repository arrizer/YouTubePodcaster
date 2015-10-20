AppKit = require 'appkit'
Feeds  = require './Feeds'

module.exports = class Server extends AppKit.Server
  init: ->
    @loadModule new Feeds(@)