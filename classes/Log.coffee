CLIColor   = require 'cli-color'
sprintf    = require('sprintf').sprintf

module.exports = class Log
  LEVELS =
    debug:
      level: 0
      colors: ['blue']
      textColors: ['blackBright']
    info:
      level: 1
      colors: ['cyan']
      textColors: []
    warn:
      level: 2
      colors: ['black','bgYellow']
      textColors: ['yellow']
    error:
      level: 3
      colors: ['red']
      textColors: ['red']
    fatal:
      level: 4
      colors: ['white','bgRedBright']
      textColors: ['red']

  @StdErr: ->
    new Log(process.stderr)
    
  constructor: (@stream) ->
    @colored = yes
    @timestamp = no
    @level = 5
    @buffer = ''
    @paused = no
    for level of LEVELS
      do (level) =>
        @[level] = (message, parameters...) =>
          @log(level, message, parameters...)

  colorize: (string, colors...) ->
    return string if !@colored or !colors? or colors.length == 0
    chain = CLIColor
    for color in colors
      chain = chain[color]
    return chain(string)

  log: (level, message, parameters...) ->
    line = ''
    line += @colorize('[' + new Date() + '] ', 'blackBright') if @timestamp
    line += @colorize('[' + level.toUpperCase() + ']', LEVELS[level].colors...)
    line += ' ' + @colorize(sprintf(message, parameters...), LEVELS[level].textColors...)
    @write line + "\n"

  write: (message) ->
    if @paused
      @buffer += message
    else
      @stream.write message, 'utf8'

  pause: ->
    @paused = yes

  resume: ->
    @paused = no
    @write @buffer
    @buffer = ''