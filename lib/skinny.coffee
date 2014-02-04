# Skinny.coffee - by Seandon 'eru' Mooy
# https://github.com/erulabs/skinnyjs
module.exports = class Skinnyjs
    constructor: (@cfg) ->
        @path                   = require 'path'
        @_                      = require 'underscore'
        @fs                     = require 'fs'
        @cfg = {} if !@cfg?
        # Configuration defaults
        # HTTP server port
        @cfg.port               = 9000 unless @cfg.port?
        # Autoreload - boolean
        @cfg.reload             = true unless @cfg.reload?
        # MongoDB server IP:PORT
        @cfg.db                 = '127.0.0.1:27017' unless @cfg.db?
        # Set the project path to our current working directory by default
        @cfg.path               = @path.normalize process.cwd() unless @cfg.path?
        # Project name is the name of this directory by default
        @cfg.project            = @cfg.path.split(@path.sep).splice(-1)[0] unless @cfg.project?
        # Directory structure - existing values are required.
        @cfg.layout             = { app: '/app', configs: '/cfg', models: '/app/models', views: '/app/views', controllers: '/app/controllers', assets: '/app/assets' } unless @cfg.layout?
        # Prepend directory structure values with our cfg.path (ie: build the full filesystem path to any given file)
        @cfg.layout[key]        = @path.normalize(@cfg.path + @cfg.layout[key]) for key, value of @cfg.layout
        # Some console colors and initial data structures
        @colors                 = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" }
        @db = false; @controllers = {}; @models = {}; @routes = {}; @configs = {}; @compiler = {};
    # Generic module loader - loads js modules with the npm "modules.exports =" pattern from the skinny.init()
    # type matches one of skinny.cfg.layout[] ie: configs, controllers, models...
    # options is an array which must have .path - .force can be passed to reload a library.
    initModule: (type, opts) ->
        if !opts.path? then return false else @path.normalize opts.path
        # Add the module to skinny - module name is opts.name or the name of the .js file that is loaded
        opts.name = if opts.name? then opts.name else opts.path.split(@path.sep).splice(-1)[0].replace '.js', ''
        # optionally clear the cache and module list
        if opts.force?
            delete require.cache[require.resolve opts.path]
            delete @[type][opts.name]
        skinny = @
        try
            @[type][opts.name] = require(skinny.path.normalize(opts.path))(skinny, opts)
        catch error
            return @error(error, { type: type, error: 'initModuleException', opts: opts })
        # pass to skinny.initModel if its in the cfg.layout.models directory
        @[type][opts.name] = @initModel @[type][opts.name], opts.name if type == "models"
        return true
    # MongoDB functionality - wrap an object with mongo functionality and return the modified object.
    # This is a massive todo - please pretend this doesnt exist :P
    initModel: (model, name) ->
        return model if typeof model.prototype == undefined
        model.prototype.name = name
        model.prototype.db = @db.collection(name)
        model.prototype.save = (cb) -> @db.insert @, () => cb() if cb?
        return model;
    # Log error via socket:
    error: (error, opts) ->
        @io.sockets.emit('__skinnyjs', { error: { message: error.message, raw: error.toString(), module: opts } })
        console.log @colors.red+'Exception!'+@colors.reset+" ->", "\n"+@colors.cyan+"Skinny details:"+@colors.reset, opts, "\n"+@colors.cyan+"stack:"+@colors.reset, error.stack
    # Skinny project init / server - takes no arguments
    init: () ->
        # Express JS defaults and listen()
        @express = require 'express' ; @server = @express()
        @server.use @express.compress()
        @server.use @express.json()
        # Static asset paths:
        @server.use '/views', @express.static @cfg.layout.views
        @server.use '/assets', @express.static @cfg.layout.assets
        @httpd = require('http').createServer @server
        @httpd.listen @cfg.port
        # Socketio init and listen()
        @io = require('socket.io').listen @httpd, { log: no }
        # MongoDB init and connect() -> adds skinny.db
        @mongo = require('mongodb');
        @mongo.MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, db) =>
            if err then return console.log @colors.red+'MongoDB error:'+@colors.reset, err else @db = db
            # Load modules!
            for moduleType in [ 'configs', 'controllers', 'models' ]
                # Read each modules directory from skinny.cfg.layout
                @fs.readdirSync(@cfg.layout[moduleType]).forEach (path) =>
                    # For each file in the directory, skinny.initModule() with the correct type and file path
                    if @fileMatch path then @initModule moduleType, { path: @cfg.layout[moduleType]+@path.sep+path }
        # Our socket.io powered quick-reload -> depends on node-watch for cross-platform functionality
        if @cfg.reload
            @watch = require 'node-watch'
            # Only watch the app and configs directory for changes
            @watch @cfg.layout.app, (file) => @fileChangeEvent(file)
            @watch @cfg.layout.configs, (file) => @fileChangeEvent(file)
    # Matches file paths that skinny uses
    fileMatch: (file) ->
        if file.match /\/\.git|\.swp$|\/assets\// then return false
        unless file.match /\.js$/ then return false else return true
    # Reload the page and compile code if required - skinny watches files and does stuff!
    fileChangeEvent: (file) ->
        if @fileMatch file
            if exists = @fs.existsSync file
                # Ignore changes to directories - this only occurs on win32
                if @fs.lstatSync(file).isDirectory() then return false
                # Pass the file to a @compiler if one matches the file extname
                if compile = @compiler[@path.extname file] then return compile(file)
            # Load the file! Force a reload of it if it exists already and send a refresh signal to the browser and console
            if @initModule file.split(@path.sep).splice(-2)[0], { path: file, force: yes, clear: !exists }
                console.log @colors.cyan+'Reloading browser for:'+@colors.reset, file.replace @cfg.path, ''
                @io.sockets.emit('__skinnyjs', { reload: { delay: 0 } })
    # Create a new SkinnyJS project template - depends on NCP for code clarity
    # Takes no arguments and copies skinnyjs templates into skinny.cfg.path/
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
                console.log '('+req.connection.remoteAddress+')', @colors.cyan+req.method+':'+@colors.reset, req.url, obj.controller+'#'+obj.action
                # build out filepath for expected view (may or may not exist)
                res.view = @cfg.layout.views+'/'+obj.controller+'/'+obj.action+'.html'
                # Run controller if it exists
                try
                    controllerOutput = @controllers[obj.controller][obj.action](req, res) if @controllers[obj.controller][obj.action]? if @controllers[obj.controller]?
                catch error
                    @error(error, { error: 'controllerException', view: res.view })
                if controllerOutput?
                    # If the controller sent headers, stop all activity - the controller is handeling this request
                    return if res.headersSent
                    # If the controller returned some data, sent it down the wire:
                    controllerOutput = JSON.stringify controllerOutput if typeof controllerOutput == "object"
                    return res.send controllerOutput if controllerOutput?
                else if @fs.existsSync res.view
                    # If the controller didn't return anything, render the view (assuming it exists)
                    return res.sendfile res.view
                # If the controller didn't return anything and the view doesn't exist (ie: we're still here!), then 404
                else return res.send '404'