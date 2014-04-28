fs = require 'fs'
spawn = require('child_process').spawn
pkg = require './package.json'

start = ->
  run "pm2 -n #{pkg.name} start #{pkg.main}"
  
stop = ->
  run "pm2 stop #{pkg.name}"

task 'start', 'Start the server application', ->
  console.log "Starting #{pkg.name}"
  start()

task 'stop', 'Stop the server application', ->
  console.log "Stopping #{pkg.name}"
  stop()

task 'dev', 'Watch for changes, auto-compile client scripts and restart nodemon', ->
  run "nodemon -q --ext coffee,html #{pkg.main}"

run = (command, next) ->
  shell = spawn('bash', ['-c',command])
  console.log '$', command
  shell.stdout.on 'data', (data) ->
    process.stdout.write data
  shell.stderr.on 'data', (data) ->
    process.stderr.write data
  shell.on 'close', (code) ->
    next(code) if next?
