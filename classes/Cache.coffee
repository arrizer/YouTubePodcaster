Memcached = require('memcached')
PREFIX = 'ytpodcaster:'

module.exports = class Cache
  @Local: -> 
    new Cache('127.0.0.1', 11211)
  
  constructor: (host, port) ->
    @memcached = new Memcached(host+':'+port)
  
  cache: (arg) ->
    arg.allow = yes unless arg.allow?
    if arg.allow == 1 or arg.allow is '1' or arg.allow == yes
      arg.allow = yes
    else
      arg.allow = no
    arg.lifetime = 0 unless arg.lifetime?
    if arg.allow
      @memcached.get PREFIX + arg.key, (error, data) =>
        if !error? and data
          arg.get(data, yes)
        else
          arg.fetch (data) =>
            if data?
              @memcached.set PREFIX + arg.key, data, arg.lifetime, (error) =>
                arg.get(data, no)
    else
      arg.fetch (data) =>
        arg.get data, no