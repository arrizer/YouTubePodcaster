express  = require 'express'
http     = require 'http'
path     = require 'path'
fs       = require 'fs'

# Configure app
app = express()
app.set "port", 9898
app.set "views", __dirname + "/views"
app.set 'view engine', 'html'
app.enable 'view cache'
app.enable 'trust proxy'
app.disable 'x-powered-by'

# Load config file
app.config = require './config.json'
app.config.path = __dirname

# Middleware
app.use express.favicon()
app.use express.logger("dev")
app.use express.methodOverride()
app.use express.static(path.join(__dirname, "public"))
app.use express.errorHandler() if "development" is app.get("env")

# Load routes
require("fs").readdirSync(__dirname + "/routes").forEach (file) ->
  require(__dirname + '/routes/' + file)(app) if path.extname(file) is '.coffee'

# Start server
http.createServer(app).listen app.get("port"), 'localhost', ->
  console.log "Listening on port " + app.get("port")