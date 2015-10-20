#!/usr/bin/env coffee

Server = require './server/Server'

config = require './config.json'
config.path = __dirname

server = new Server(config)
server.start()