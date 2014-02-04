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
        return true unless @path.extname(opts.path) == ".js"
        delete require.cache[require.resolve opts.path] if opts.force?
        # Add the module to skinny - module name is opts.name or the name of the .js file that is loaded
        opts.name = if opts.name? then opts.name else opts.path.split(@path.sep).splice(-1)[0].replace '.js', ''
        delete @[type][opts.name] if opts.clear? if @[type][opts.name]? if @[type]?
        # Returning false doesn't notify browser of file change (in the case of clearing - no need to post updates)
        return false if opts.clear?
        try
            @[type][opts.name] = require(@path.normalize(opts.path))(@, opts)
        catch error
            @io.sockets.emit('__skinnyjs', { error: { message: error.message, raw: error.toString(), module: opts } })
            console.log 'initModule failure on', type, opts, 'error:', error.message, error.toString()
            return false
        # pass to skinny.initModel if its in the cfg.layout.models directory
        @[type][opts.name] = @initModel @[type][opts.name], opts.name if type == "models"
        return true
    # MongoDB functionality - wrap an object with mongo functionality and return the modified object.
    initModel: (model, name) ->
        return model if typeof model.prototype == undefined
        model.prototype.name = name
        model.prototype.db = @db.collection(name)
        model.prototype.all = (cb) -> @db.find().toArray (err, results) => cb(results)
        model.prototype.save = (cb) -> @db.insert @, () => cb() if cb?
        return model;
    # Skinny project init / server - takes no arguments
    init: () ->
        # Express JS defaults and listen()
        @express    = require 'express'
        @server     = @express()
        # Gzip requests and use JSON by default
        @server.use @express.compress()
        @server.use @express.json()
        # Static asset paths:
        @server.use '/views', @express.static @cfg.layout.views
        @server.use '/assets', @express.static @cfg.layout.assets
        @httpd      = require('http').createServer @server
        @httpd.listen @cfg.port
        # Socketio init and listen()
        @io         = require('socket.io').listen @httpd, { log: no }
        # MongoDB init and connect() -> adds skinny.db
        @mongo =  require('mongodb');
        @mongo.MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, db) =>
            if err then return console.log @colors.red+'MongoDB error:'+@colors.reset, err else @db = db
            # Load modules!
            for moduleType in [ 'configs', 'controllers', 'models' ]
                # Read each modules directory from skinny.cfg.layout
                @fs.readdirSync(@cfg.layout[moduleType]).forEach (path) =>
                    # For each file in the directory, skinny.initModule() with the correct type and file path
                    @initModule moduleType, { path: @cfg.layout[moduleType]+@path.sep+path }
        # Our socket.io powered quick-reload -> depends on node-watch for cross-platform functionality
        if @cfg.reload
            watch   = require 'node-watch'
            # Common action for files that change
            watchAction = (file) =>
                opts = { path: file, force: yes }
                # Skip temporary, swap, vendor, asset and version control files
                skip = true if file.match @path.set+'.git' or file.match @path.set+'assets' or file.match @path.set+'vendor' or file.substr(-4) == '.tmp' or file.substr(-4) == '.swp'
                # Remove modules that have been deleted (also don't continue)
                opts.clear = true unless @fs.existsSync file
                # Only fires on win32 - ignore changes to directory caught by watch
                skip = true if @fs.lstatSync(file).isDirectory() if !opts.clear?
                # If we have a compiler target matching the extension of the file, fire that off instead of continuing
                return @compiler[@path.extname(file)](file) if @compiler? and @compiler[@path.extname(file)]
                # Load the file! Force a reload of it if it exists already and send a refresh signal to the browser and console
                unless skip? 
                    if @initModule file.split(@path.sep).splice(-2)[0], opts
                        console.log @colors.cyan+'Reloading browser for:'+@colors.reset, file.replace @cfg.path, ''
                        @io.sockets.emit('__skinnyjs', { reload: { delay: 0 } })
            # Only watch the app and configs directory for changes
            watch @cfg.layout.app, (file) => watchAction(file)
            watch @cfg.layout.configs, (file) => watchAction(file)
    # Create a new SkinnyJS project template - depends on NCP for code clarity
    # Takes no arguments and copies skinnyjs templates into skinny.cfg.path/
    install: (target) ->
        target = @cfg.path+dirName unless target?
        @fs.mkdirSync target unless @fs.existsSync target
        # Recursively copy the template project into our target
        require('ncp').ncp __dirname+'/templateProject', target, (err) -> console.log err if err
    # Parses app.routes and adds them to express
    parseRoutes: () ->
        app._.each app.routes, (obj, route) ->
            # For each route, add to app.server (default method is 'get')
            app.server[obj.method or 'get'] route, (req, res) ->
                # Run catchall route if we've found a controller
                app.controllers[obj.controller]['*'](req, res) if app.controllers[obj.controller]['*']? if app.controllers[obj.controller]?
                # Log concise request to console
                console.log '('+req.connection.remoteAddress+')', app.colors.cyan+req.method+':'+app.colors.reset, req.url, obj.controller+'#'+obj.action
                # build out filepath for expected view (may or may not exist)
                res.view = app.cfg.layout.views+'/'+obj.controller+'/'+obj.action+'.html'
                # Run controller if it exists
                controllerOutput = app.controllers[obj.controller][obj.action](req, res) if app.controllers[obj.controller][obj.action]? if app.controllers[obj.controller]?
                if controllerOutput?
                    # If the controller sent headers, stop all activity - the controller is handeling this request
                    return if res.headersSent
                    # If the controller returned some data, sent it down the wire:
                    controllerOutput = JSON.stringify controllerOutput if typeof controllerOutput == "object"
                    return res.send controllerOutput if controllerOutput?
                else
                    # If the controller didn't return anything, render the view (assuming it exists)
                    return res.sendfile res.view if @fs.existsSync res.view
                # If the controller didn't return anything and the view doesn't exist (ie: we're still here!), then 404
                return res.send '404'