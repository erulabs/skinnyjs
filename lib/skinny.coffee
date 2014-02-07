# Skinny.coffee - by Seandon 'eru' Mooy
# https://github.com/erulabs/skinnyjs
module.exports = class Skinnyjs
  constructor: (@cfg) ->
    @path = require 'path'
    @_ = require 'underscore'
    @fs = require 'fs'
    @cfg = {} if !@cfg?
    # Configuration defaults
    @cfg.port = 9000 unless @cfg.port?
    # Autoreload - boolean
    @cfg.reload = true unless @cfg.reload?
    # MongoDB server IP:PORT
    @cfg.db = '127.0.0.1:27017' unless @cfg.db?
    # Set the project path to our current working directory by default
    @cfg.path = @path.normalize process.cwd() unless @cfg.path?
    # Project name is the name of this directory by default
    @cfg.project = @cfg.path.split(@path.sep).splice(-1)[0] unless @cfg.project?
    # Directory structure - existing values are required.
    @cfg.layout = { app: '/app', configs: '/configs', models: '/app/models', views: '/app/views', controllers: '/app/controllers', assets: '/app/client' } unless @cfg.layout?
    # Prepend directory structure values with our cfg.path (ie: build the full filesystem path to any given file)
    @cfg.layout[key] = @path.normalize(@cfg.path + @cfg.layout[key]) for key, value of @cfg.layout
    # Skinny module list (must corespond to directory names)
    @cfg.moduleTypes = [ 'configs', 'controllers', 'models' ]
    # Some console colors and initial data structures
    @clr = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" }
    @db = false; @controllers = {}; @models = {}; @routes = {}; @configs = {}; @compiler = {}; @cache = {};
  # MongoDB functionality - wrap an object with mongo functionality and return the modified object.
  initModel: (model, name) ->
    # Do not extend non-functions - leave them alone
    if typeof model.prototype == undefined then return model else skinny = @
    # Give each model .find, .new, .remove, etc which is a loose wrapper around the mongo collection
    if !model.find? then model.find = (query, cb) ->
      if typeof query == 'function' then cb = query ; query = {}
      skinny.db.collection(name).find(query).toArray (err, results) =>
        # Append the functionality of the model into each result. TODO: Improve this code
        results.forEach (result) =>
          skinny._.each model, (value, key) => result[key] = value unless key in [ 'db', 'find' ]
          # Give each model a .save(), which is just a shortcut to a collection insert
          if !result.save? then result.save = (cb) -> skinny.db.collection(name).insert @, () -> if cb? then cb()
        cb results
    if !model.new? then model.new = () -> return @
    if !model.remove? then model.remove = (query, cb) ->
      if typeof query == 'function' then cb = query ; query = {}
      skinny.db.collection(name).remove query, () -> if cb? then cb()
    # Add a direct reference to the collection here as well.
    if !model.collection? then model.collection = @db.collection(name)
    return model
  # Generic module loader - loads js modules with the npm "modules.exports =" pattern from the skinny.init()
  # type matches one of skinny.cfg.layout[] ie: configs, controllers, models...
  # options is an array which must have .path - .force can be passed to reload a library.
  initModule: (type, opts) ->
    # Returning true passes task to reloader - returning false refuses reload
    if !opts.path? then return false else @path.normalize opts.path
    if !opts.path.match /\.js$/ or opts.path.match /\/assets\// then return true
    # if this is a client module, continue to the reloader - it's not a server module
    if opts.path.match /\/client\// then return true
    # If this is not a known module type then do not reload page - instead log a message - TODO: auto-restart skinny
    if type not in @cfg.moduleTypes then console.log @clr.cyan+'Unhandled change on:'+@clr.reset, opts.path, @clr.cyan+"you may want to restart Skinny"+@clr.reset ; return false
    # Add the module to skinny - module name is opts.name or the name of the .js file that is loaded
    opts.name = if opts.name? then opts.name else opts.path.split(@path.sep).splice(-1)[0].replace '.js', ''
    # optionally clear the cache and module list
    if opts.force? then delete require.cache[require.resolve opts.path] ; delete @[type][opts.name]
    module = require @path.normalize opts.path
    if typeof module != 'function' then return console.log @clr.red+"WARNING:"+@clr.reset, 'the', type.substr(0, type.length-1), '"'+opts.name+'"', 'is malformed (not a function). It is being ignored'
    try @[type][opts.name] = module(@, opts)
    catch error
      return @error error, { type: type, error: 'initModuleException', opts: opts }
    # pass to skinny.initModel if its in the cfg.layout.models directory
    @[type][opts.name] = @initModel @[type][opts.name], opts.name if type == "models"
    return true
  # Log error via socket:
  error: (error, opts) ->
    @io.sockets.emit '__skinnyjs', { error: { message: error.message, raw: error.toString(), module: opts } }
    console.log @clr.red+'Exception! ->', "\n"+@clr.cyan+"Skinny details:"+@clr.reset, opts, "\n"+@clr.cyan+"stack:"+@clr.reset, error.stack
  # Skinny project init / server - takes no arguments
  init: (cb) ->
    # Express JS defaults and listen()
    @express = require 'express' ; @server = @express()
    @server.use @express.json()
    @server.use @express.compress()
    @server.use '/views', @express.static @cfg.layout.views
    @server.use '/assets', @express.static @cfg.layout.assets
    @httpd = require('http').createServer @server
    @httpd.listen @cfg.port
    # Socketio init and listen()
    @io = require('socket.io').listen @httpd, { log: no }
    # MongoDB init and connect() -> defines @db
    @mongo = require 'mongodb'
    @mongo.MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, db) =>
      if err then return console.log @clr.red+'MongoDB error:'+@clr.reset, err else @db = db
      # Read each modules directories and for each file in the directory, skinny.initModule(file) with the correct type and file path
      for moduleType in @cfg.moduleTypes
        @fs.readdirSync(@cfg.layout[moduleType]).forEach (path) => if @fileMatch path then @initModule moduleType, { path: @cfg.layout[moduleType]+@path.sep+path }
      # Delay application init 100 ms - prevents the need for complex ordering - gives time for modules to load
      setTimeout () -> if cb? then cb(),
      50
    # Our socket.io powered quick-reload -> depends on node-watch for cross-platform functionality
    # fires @fileChangeEvent on file changes in the 'watched' directories
    if @cfg.reload
      @watch = require 'node-watch'
      @watch @cfg.layout.app, (file) => @fileChangeEvent(file)
      @watch @cfg.layout.configs, (file) => @fileChangeEvent(file)
  # Matches file paths that skinny uses
  fileMatch: (file) -> if file.match /\/\.git|\.swp$|\.tmp$/ then return false else return true
  # Reload the page and compile code if required - skinny watches files and does stuff!
  fileChangeEvent: (file) ->
    if @fileMatch file
      if exists = @fs.existsSync file
        # Ignore changes to directories - this only occurs on win32
        if @fs.lstatSync(file).isDirectory() then return false
        # Pass the file to a @compiler if one matches the file extname
        if compile = @compiler[@path.extname file] then return compile file
      else delete @cache[file] if @cache[file]?
      # Load the file! Force a reload of it if it exists already and send a refresh signal to the browser and console
      if @initModule file.split(@path.sep).splice(-2)[0], { path: file, force: yes, clear: !exists }
        console.log '-->', @clr.green+'Reloading browser'+@clr.reset, '-', file.replace(@cfg.path, '')
        @io.sockets.emit('__skinnyjs', { reload: { delay: 0 } })
  # Create a new SkinnyJS project template - copies skinnyjs templates into skinny.cfg.path/
  install: (target) ->
    target = @cfg.path+dirName unless target?
    @fs.mkdirSync target unless @fs.existsSync target
    # Recursively copy the template project into our target
    require('ncp').ncp __dirname+'/templateProject', target, (err) -> console.log err if err
  # Parses app.routes and adds them to express
  parseRoutes: () ->
    @_.each @routes, (obj, route) =>
      # For each route, add to @server (default method is 'get')
      @server[obj.method or 'get'] route, (req, res) =>
        # Run catchall route if we've found a controller
        @controllers[obj.controller]['*'](req, res) if @controllers[obj.controller]['*']? if @controllers[obj.controller]?
        # Log concise request to console
        console.log '('+req.connection.remoteAddress+')', @clr.cyan+req.method+':'+@clr.reset, req.url, obj.controller+'#'+obj.action
        # build out filepath for expected view (may or may not exist)
        res.view = @cfg.layout.views+'/'+obj.controller+'/'+obj.action+'.html'
        # Run controller if it exists
        if @controllers[obj.controller]? and @controllers[obj.controller][obj.action]?
          try controllerOutput = @controllers[obj.controller][obj.action](req, res)
          catch error
            @error(error, { error: 'controllerException', view: res.view })
          if controllerOutput?
            # If the controller sent headers, stop all activity - the controller is handeling this request
            return false if res.headersSent
            # If the controller returned some data, sent it down the wire:
            controllerOutput = JSON.stringify controllerOutput if typeof controllerOutput == "object"
            return res.send controllerOutput if controllerOutput?
        # If the catchall sent headers, then do not 404 (or try to render view)
        return false if res.headersSent
        # We'll cache file paths that exist to avoid running fs calls per request if possible.
        if !@cache[res.view]? then @cache[res.view] = @fs.existsSync res.view
        # If the controller didn't return anything, render the view (assuming it exists)
        if @cache[res.view] then return res.sendfile res.view else res.send '404'