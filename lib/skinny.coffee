# Skinny.coffee - by Seandon 'eru' Mooy
# https://github.com/erulabs/skinnyjs
module.exports = class Skinnyjs
  constructor: (@cfg) ->
    @path = require 'path'
    @_ = require 'underscore'
    @fs = require 'fs'
    @cfg = {} if !@cfg?
    # Configuration defaults
    @cfg.env = 'dev' if !@cfg.env?
    @cfg.port = 9000 unless @cfg.port?
    # Autoreload - boolean
    @cfg.reload = true unless @cfg.reload?
    # MongoDB server IP:PORT
    @cfg.db = '127.0.0.1:27017' unless @cfg.db?
    # Set the project path to our current working directory by default
    @cfg.path = @path.normalize process.cwd() unless @cfg.path?
    # Project name is the name of this directory by default
    @cfg.project = @cfg.path.split(@path.sep).splice(-1)[0].replace('.', '') unless @cfg.project?
    # Compile all files before starting skinny
    @cfg.precompile = yes
    # Directory structure - existing values are required.
    if !@cfg.layout? then @cfg.layout = 
      app: '/app'
      configs: '/configs'
      test: '/test'
      models: '/app/models'
      views: '/app/views'
      controllers: '/app/controllers'
      assets: '/app/client'
    # Prepend directory structure values with our cfg.path (ie: build the full filesystem path to any given file)
    @cfg.layout[key] = @path.normalize(@cfg.path + @cfg.layout[key]) for key, value of @cfg.layout
    # Skinny module list (must corespond to directory names)
    @cfg.moduleTypes = [ 'configs', 'models', 'controllers' ]
    # Some console colors and initial data structures
    @clr = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", gray: "\u001b[1;30m", reset: "\u001b[0m" }
    @db = false; @controllers = {}; @models = {}; @routes = {}; @configs = {}; @compiler = {}; @cache = {};
  # MongoDB functionality - wrap an object with mongo functionality and return the modified object.
  initModel: (model, name) ->
    # FYI, this method can and will be called before mongodb is ready. Therefore do not call @db directly
    if model isnt undefined then skinny = @ else return model
    bind = (instance) ->
      instance.save = protoInstance.save
      instance.remove = protoInstance.remove
      for methodName, method of model
        if model.hasOwnProperty(methodName) 
          unless methodName in [ 'find', 'new', 'remove', 'collection', 'prototype', '__super__' ]
            if !instance[methodName]? then instance[methodName] = method
      return instance
    protoInstance = 
      save: (cb) ->
        out = { _id: @_id }
        for k, v of @
          if typeof v isnt "function"
            unless k in [ 'prototype', '__super__' ]
              out[k] = v
        try skinny.db.collection(name).save out, (error, inserted) -> if cb? then cb(error, inserted)
        catch error then return skinny.error error, { type: 'database', error: 'modelSaveException', details: error.message }
      remove: (cb) ->
        if !@_id? then if cb? then cb(); return true
        skinny.db.collection(name).remove { _id: @_id }, () -> if cb? then cb()
    # Give each model .find, .new, .remove, etc which is a loose wrapper around the mongo collection
    if !model.find? then model.find = (query, cb) ->
      if typeof query == 'function' then cb = query ; query = {}
      if skinny.cfg.env is 'test' then return cb([ {} ])
      skinny.db.collection(name).find(query).toArray (err, results) =>
        for instance in results
          instance = bind(instance)
        cb results
    if !model.new? then model.new = () -> return bind({})
    if !model.remove? then model.remove = (query, cb) ->
      if typeof query == 'function' then cb = query ; query = {}
      if cb == undefined then cb = () -> return true
      skinny.db.collection(name).remove query, cb
    if !model.collection? then model.collection = () => return @db.collection(name)
    return model
  # Generic module loader - loads js modules with the npm "modules.exports =" pattern from the skinny.init()
  # type matches one of skinny.cfg.layout[] ie: configs, controllers, models...
  # options is an array which must have .path - .force can be passed to reload a library.
  initModule: (type, opts) ->
    # Returning true passes task to reloader - returning false refuses reload
    # if this isn't javascript or if its a client-side file, we're not interested, so move on.
    if !opts.path? then return false else @path.normalize opts.path
    isntJavascript = !!!opts.path.match /\.js$/
    isClient = !!opts.path.match /\/client\//
    if isntJavascript or isClient then return true
    if !!opts.path.match /\/test\/*.js$/ then return false
    # If this is not a known module type then do not reload page - instead log a message - TODO: auto-restart skinny
    if type not in @cfg.moduleTypes then @log @clr.cyan+'Unhandled change on:'+@clr.reset, opts.path, @clr.cyan+"you may want to restart Skinny"+@clr.reset ; return false
    # Add the module to skinny - module name is opts.name or the name of the .js file that is loaded
    opts.name = if opts.name? then opts.name else opts.path.split(@path.sep).splice(-1)[0].replace '.js', ''
    # optionally clear the cache and module list
    if opts.force? then delete require.cache[require.resolve opts.path]; delete @[type][opts.name]
    # Require the code and throw errors/return if needed
    try module = require @path.normalize opts.path
    catch error then return @error error, { type: type, error: 'moduleRequireException', details: opts }
    # If the module interpreted correctly (ie: we're still here), but isn't actually a skinny model then return
    if typeof module isnt 'function' then @[type][opts.name] = module; return true
    # Pass the task off to @initModel if we found it in the models directory
    if type is "models"
      try @[type][opts.name] = @initModel module(@, opts), opts.name
      catch error then return @error error, { type: type, error: 'moduleExecutionException', details: opts }
    # otherwise run the sucker!
    else @[type][opts.name] = module(@, opts)
    return true
  # Default logger
  log: () -> if @cfg.env is 'dev' then console.log.apply @, arguments
  # Log error via socket:
  error: (error, opts) ->
    if @cfg.env is 'dev' and @io? then @io.sockets.emit '__skinnyjs', { error: { message: error.message, raw: error.toString(), module: opts } }
    @log @clr.red+'Exception: '+opts.error+@clr.reset, 'in', (if opts.details? and opts.details.name? then '"'+opts.details.name+'":' else opts), error.toString()
    if error.stack? then @log "\n"+@clr.cyan+"stack:"+@clr.reset, error.stack
    if opts.details? then @log @clr.cyan+"the Skinny:"+@clr.reset, opts.details
  # Compile all files in the project without including them
  precompile: (callback) ->
    if !@cfg.precompile then return callback()
    # Track calls to the compiler
    activeCompileCalls = 0
    # Read each modules directories and for each file in the directory, skinny.initModule(file) with the correct type and file path
    for moduleType in @cfg.moduleTypes
      @fs.readdirSync(@cfg.layout[moduleType]).forEach (path) =>
        if @fileMatch path
          file = @cfg.layout[moduleType] + @path.sep + path
          if @compiler[@path.extname file]?
            activeCompileCalls++
            @compiler[@path.extname file] file, () ->
              activeCompileCalls--
              if activeCompileCalls == 0
                callback()
  # Skinny project init / server - takes no arguments
  init: (cb) ->
    # Express JS defaults and listen()
    @express = require 'express' ; @server = @express()
    # MongoDB init and connect() -> defines @db
    @mongo = require 'mongodb'
    @mongo.MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, db) => if err then return @log @clr.red+'MongoDB error:'+@clr.reset, err else @db = db
    # Explicity look for the compiler script.
    compilerPath = @cfg.layout.configs + @path.sep + 'compiler.js'
    if @fs.existsSync compilerPath then @initModule 'configs', { path: compilerPath }
    @precompile () =>
      for moduleType in @cfg.moduleTypes
        @fs.readdirSync(@cfg.layout[moduleType]).forEach (path) =>
          if @fileMatch path and path.substr(-3) is '.js'
            file = @cfg.layout[moduleType] + @path.sep + path
            @initModule moduleType, { path: file }
      # Run skinny init before HTTP listening - this allows the user to override any @server settings they want
      if cb? then cb(@)
      # JSON and Gzip by default
      @server.use @express.json()
      @server.use @express.compress()
      # Allow parsing of POST and GET arguments by default.
      @server.use @express.urlencoded()
      # Static asset routes -> this should be improved.
      @server.use '/views', @express.static @cfg.layout.views
      @server.use '/assets', @express.static @cfg.layout.assets
      # Node HTTP init and listen()
      @http = require('http')
      @httpd = @http.createServer @server
      try @httpd.listen @cfg.port, () => @log '-->', @clr.green+'Listening on port:'+@clr.reset, @cfg.port
      catch error then return @error error, { type: 'skinnyCore', error: 'httpListenException' }
      # Socketio init and listen()
      try @io = require('socket.io').listen @httpd, { log: no }
      catch error then return @error error, { type: 'skinnyCore', error: 'socketioListenException' }
      # Our socket.io powered quick-reload -> depends on node-watch for cross-platform functionality
      # fires @fileChangeEvent on file changes in the 'watched' directories
      @watch = require 'node-watch'
      for watched in [ 'app', 'configs', 'test' ]
        @watch @cfg.layout[watched], (file) => @fileChangeEvent(file)
  # Matches file paths that skinny uses
  fileMatch: (file) ->
    if !false then return true
    if file.match /\/\.git|\.swp$|\.tmp$/ then return false else return true
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
        #@log '-->', @clr.green+'Reloading browser'+@clr.reset, 'for', file
        @io.sockets.emit('__skinnyjs', { reload: { delay: 0 } })
  # Create a new SkinnyJS project template - copies skinnyjs templates into skinny.cfg.path/
  install: (target, cb) ->
    # TODO: This should parse and modify the new projects package.json
    # setting the skinnyjs dep to the version which created it
    target = @cfg.path+dirName unless target?
    @fs.mkdirSync target unless @fs.existsSync target
    # Recursively copy the template project into our target
    require('ncp').ncp __dirname+'/templateProject', target, (err) ->
      @log err if err
      if cb? then cb()
  # Parses app.routes and adds them to express
  parseRoutes: (routes, multirouteName) ->
    if !routes? then routes = @routes
    @_.each routes, (obj, route) =>
      if obj.push?
        @parseRoutes(obj, route)
      else if typeof obj is 'object'
        if multirouteName? then route = multirouteName
        @setRoute(obj, route)
  setRoute: (obj, route) ->
    # For each route, add to @server (default method is 'get')
    @server[obj.method?.toLowerCase() or 'get'] route, (req, res) =>
      # Run catchall route if we've found a controller
      @controllers[obj.controller]['*'](req, res) if @controllers[obj.controller]['*']? if @controllers[obj.controller]?
      # Log concise request to console
      @log '('+req.connection.remoteAddress+')', @clr.cyan+req.method+':'+@clr.reset, req.url, @clr.gray+'->'+@clr.reset, obj.controller+@clr.gray+'#'+@clr.reset+obj.action
      # build out filepath for expected view (may or may not exist)
      res.view = @cfg.layout.views+'/'+obj.controller+'/'+obj.action+'.html'
      # Run controller if it exists
      if @controllers[obj.controller]? and @controllers[obj.controller][obj.action]?
        try controllerOutput = @controllers[obj.controller][obj.action](req, res)
        catch error then @error error, { error: 'controllerException', details: { name: obj.controller, action: obj.controller } }
        if controllerOutput?
          # Allow a manual bypass
          if controllerOutput.skip? then return false
          # If the controller sent headers, stop all activity - the controller is handeling this request
          return false if res.headersSent
          # If the controller returned some data, sent it down the wire:
          controllerOutput = JSON.stringify controllerOutput if typeof controllerOutput == "object"
          if controllerOutput?
            return res.send controllerOutput
      # If the catchall sent headers, then do not 404 (or try to render view)
      return false if res.headersSent
      # We'll cache file paths that exist to avoid running fs calls per request if possible.
      if !@cache[res.view]? then @cache[res.view] = @fs.existsSync res.view
      # If the controller didn't return anything, render the view (assuming it exists)
      if @cache[res.view]
        return res.sendfile res.view
      else
        res.send '404'
