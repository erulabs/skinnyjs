# Skinny.js by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs
# A micro ORM-less Javascript MVC Framework that makes your MVC look fat
"use strict"; # SkinnyJS requirements:
fs      = require 'fs'
http    = require 'http'
path    = require 'path'
mongo   = require('mongodb').MongoClient
_       = require 'underscore'
watch   = require 'node-watch'
coffee  = require 'coffee-script'
sass    = require 'node-sass'
colors  = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" } # Console colors for logging
module.exports = class Skinnyjs
    constructor: (@cfg) ->
        @cfg = {} if !@cfg? # Configuration defaults
        @cfg.port               = 9000 unless @cfg.port?
        @cfg.reload             = true unless @cfg.reload?
        @cfg.path               = process.cwd() unless @cfg.path?
        @cfg.db                 = '127.0.0.1:27017' unless @cfg.db?
        @cfg.project            = @cfg.path.split('/').splice(-1)[0] unless @cfg.project?
        @cfg.layout             = {} unless @cfg.layout?
        @cfg.layout.app         = @cfg.path + '/app' unless @cfg.layout.app?
        @cfg.layout.cfg         = @cfg.path + '/cfg' unless @cfg.layout.cfg?
        @cfg.layout.models      = @cfg.layout.app + '/models' unless @cfg.layout.models?
        @cfg.layout.views       = @cfg.layout.app + '/views' unless @cfg.layout.views?
        @cfg.layout.controllers = @cfg.layout.app + '/controllers' unless @cfg.layout.controllers?
        @cfg.layout.assets      = @cfg.layout.app + '/assets' unless @cfg.layout.assets?
        @db = false; @controllers = {}; @models = {}; @routes = {}; # Skinny objects
    Model: (skinny, name, model) -> # Skinny Model -> Take a js object and add some mongodb functionaltiy -> almost like a real framework :P
        instance = model skinny
        collection = skinny.db.collection(name)
        instance.prototype.find = (opts) -> collection.find(opts)
        instance.prototype.all = (cb) ->
            collection.find().toArray (err, instances) ->
                console.log 'MongoDB error on ' + name + '.all():', err if err
                cb(instances)
        return instance
    init: (cb) -> # Initialize a SkinnyJS application
        lazyLoad = 0
        fs.readdir @cfg.layout.controllers, (err, controllers) =>
            controllers.forEach (controllerPath) =>
                return unless @initController controllerPath
                cb() if ++lazyLoad == 2
        fs.readdir @cfg.layout.models, (err, models) =>
            models.forEach (modelPath) =>
                return unless @initModel modelPath
                cb() if ++lazyLoad == 2
    initController: (controllerPath) -> # read and load Skinny Model
        return false unless controllerPath.substr(-3) == '.js'
        name = controllerPath.replace '.js', ''
        controller = require @cfg.layout.controllers + '/' + controllerPath
        if @controllers[name]?
            delete require.cache[require.resolve(@cfg.layout.controllers + '/' + controllerPath)]
        @controllers[name] = controller @
    initModel: (modelPath) -> # read and load Skinny Controller
        return false unless modelPath.substr(-3) == '.js'
        name = modelPath.replace '.js', ''
        model = require @cfg.layout.models + '/' + modelPath
        @models[name] = new @Model @, name, model
    server: () -> # SkinnyJS services wrapper
        @express = require 'express'
        @socketio = require 'socket.io'
        @web = @express()
        @web.use '/views', @express.static @cfg.layout.views
        @web.use '/assets', @express.static @cfg.layout.assets
        @web.use @express.json()
        @httpd = http.createServer @web
        @routes = require @cfg.layout.cfg + '/routes.js'
        overrides = require(@cfg.layout.cfg + '/application.js')(@)
        @web.set 'port', @cfg.port
        @autoreload() if @cfg.reload
        @httpd.listen @cfg.port
        @io = @socketio.listen @httpd, { log: no }
        #@io.sockets.on 'connections', (socket) -> # Do something with sockets
        mongo.connect 'mongodb://' + @cfg.db + '/' + @cfg.project, (err, @db) =>
            return console.log 'MongoDB error:', err if err
            @init () => @parseRoutes()
    parseRoutes: () -> # Parse the already loaded routes.js and create required expressjs routes
        _.each @routes, (value, key) =>
            method = 'get'
            if typeof value == 'string'
                controller = value.split('#')[0]
                action = value.split('#')[1]
            else if typeof value == 'object'
                controller = value.controller
                action = value.action
                method = value.method if value.method?
            route = true # If no controller or action is defined, just check for the view
            route = false if !@controllers[controller]? or !@controllers[controller][action]?
            @controllers[controller]['*']() if @controllers[controller]? and @controllers[controller]['*']? # Run the catchall function if its defined
            @web[method] key, (req, res) => # express.js route -> @web is express.app -> we're adding .get, .post... app[method](), etc.
                console.log '('+req.connection.remoteAddress+')', colors.cyan+req.method+colors.reset+':', req.url, colors.cyan+'->'+colors.reset, controller+'#'+action
                res.view = @cfg.layout.views + '/' + controller + '/' + action + '.html'
                ctrlTactic = @controllers[controller][action](req, res) if route
                console.log 'No route for', controller + '#' + action, ' Controllers:', @controllers if !route
                return if res.headersSent # If the controller already sent headers to the browser, do nothing
                return res.sendfile res.view if !ctrlTactic? # Send a file if the controller didn't intercept
                return if !ctrlTactic # If the controller returned "false", do nothing (allows the controller full control over the request)
                ctrlTactic = JSON.stringify ctrlTactic if typeof ctrlTactic == "object" # if the controller returned an object, JSONify it and render the JSON
                res.send ctrlTactic # Send w/e we have from the controller
    autoreload: () -> # Watch the project directory and reload the browser when required. Also calls compileAsset() on things like coffeescript
        watch @cfg.path, (file) =>
            return true if path.extname(file) == '.tmp' or path.extname(file) == '.swp' or file.match '/.git/'
            @compileAsset file, () =>
                @initController file.replace @cfg.layout.controllers + '/', '' if file.match '/controllers/'
                if file.match '/cfg/' # Special conditions for Skinny configuration files - delete require.cache and reload express (or rather, @server())
                    delete require.cache[require.resolve(file)]
                    @server() # Probably not the best idea to always reload if anything is changed here, but we'll leave it transparent.
                console.log colors.cyan+'Browser reloading:'+colors.reset, file.replace(@cfg.path, '')
                @io.sockets.emit '__reload', { delay: 0 } # Configurable reload delay
    compileAsset: (file, cb) -> # Compiles common assets... We could use something like Gulp or Grunt or etc etc etc, but this dead simple - compile coffeescript and scss
        if file.substr(-7) == '.coffee'
            fs.readFile file, 'utf8', (err, rawCode) =>
                console.log colors.red+'compileAsset() error:'+colors.reset, err if err
                console.log colors.cyan+'CoffeeScript:'+colors.reset, file.replace(@cfg.path, '')
                try
                    cs = coffee.compile rawCode
                catch error
                    return console.log colors.red+'CoffeeScript error:'+colors.reset, file.replace(@cfg.path, '')+':', error.message, "on lines:", error.location.first_line+'-'+error.location.last_line  
                unless error?
                    fs.writeFile file.replace('.coffee', '.js'), cs, (err) -> console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.coffee', '.js'), 'error:', err if err
        else if file.substr(-5) == '.scss'
            sass.render 
                file: file
                success: (css) => fs.writeFile file.replace('.scss', '.css'), css, (err) -> console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.scss', '.css'), 'error:', err if err
                error: (error) => console.log('SCSS Compile error:', error);
        else cb()
    install: () -> # Build a working SkinnyJS project
        fsCalls = 0
        for component, path of @cfg.layout
            fsCalls++
            fs.mkdir path, (err) =>
                return console.log err if err
                if --fsCalls == 0  # Development / intro / temporary things - this will be removed and moved into the task runner's init()
                    fs.mkdir @cfg.path + '/app/views/home', (err) =>
                        return console.log err if err
                        @installTemplates()
    installTemplates: () -> # Install templates for a default/preview SkinnyJS project
        templates = [ '/cfg/routes.js', '/cfg/application.js', '/app/server.js', '/app/views/home/home.html', '/app/controllers/home.js', '/app/models/thing.js', '/app/assets/socket.io.min.js', '/app/assets/reload.js' ]
        templates.forEach (template) => fs.createReadStream(__dirname + template).pipe fs.createWriteStream @cfg.path + template