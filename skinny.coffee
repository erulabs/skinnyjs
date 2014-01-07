# Skinny.js by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs
# A micro ORM-less Javascript MVC Framework that makes your MVC look fat
"use strict"; # SkinnyJS requirements:
fs      = require 'fs'
http    = require 'http'
mongo   = require('mongodb').MongoClient
_       = require 'underscore'
watch   = require 'node-watch'
coffee  = require 'coffee-script'
sass    = require 'node-sass'
colors  = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" } # Console colors for logging
class Skinnyjs
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
        @db             = false # Initialize Skinny components
        @controllers    = {}
        @models         = {}
        @routes         = {}
    Model: (skinny, name, model) -> # Skinny Model -> Take a js object and add some mongodb functionaltiy -> almost like a real framework :P
        instance = model skinny
        collection = skinny.db.collection(name)
        instance.prototype.find = (opts) ->
            collection.find(opts)
        instance.prototype.all = (cb) ->
            collection.find().toArray (err, instances) ->
                console.log 'MongoDB error on ' + name + '.all():', err if err
                cb(instances)
        return instance
    init: (cb) -> # Initialize a SkinnyJS application
        skinny = @
        lazyLoad = 0
        # Read and init
        fs.readdir skinny.cfg.layout.controllers, (err, controllers) ->
            controllers.forEach (controllerPath) ->
                return unless skinny.initController controllerPath
                cb() if ++lazyLoad == 2
        fs.readdir skinny.cfg.layout.models, (err, models) ->
            models.forEach (modelPath) ->
                return unless skinny.initModel modelPath
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
        skinny = @
        # Initialize express
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
        mongo.connect 'mongodb://' + @cfg.db + '/' + @cfg.project, (err, db) ->
            return console.log 'MongoDB error:', err if err
            skinny.db = db
            skinny.init () -> skinny.parseRoutes()
    autoreload: () -> # Watch the project directory and reload the browser when required. Also calls compileAsset() on things like coffeescript
        skinny = @
        watch @cfg.path, (file) ->
            return if file.match '/.git/' or file.match '.swp'
            skinny.compileAsset file, () ->
                skinny.initController file.replace skinny.cfg.layout.controllers + '/', '' if file.match '/controllers/'
                if file.match '/cfg/' # Special conditions for Skinny configuration files - delete require.cache and reload express (or rather, skinny.server())
                    delete require.cache[require.resolve(file)]
                    skinny.server() # Probably not the best idea to always reload if anything is changed here, but we'll leave it transparent.
                console.log colors.cyan+'browser reloading:'+colors.reset, file.replace(skinny.cfg.path, '')
                skinny.io.sockets.emit '__reload', { delay: 0 } # Configurable reload delay
    compileAsset: (file, cb) -> # Compiles common assets... We could use something like Gulp or Grunt or etc etc etc, but this dead simple - compile coffeescript and scss
        skinny = @
        if file.substr(-7) == '.coffee'
            fs.readFile file, 'utf8', (err, rawCode) ->
                console.log colors.red+'autoreload readfile error:'+colors.reset, err if err
                console.log colors.cyan+'autocompiling coffeescript:'+colors.reset, file.replace(skinny.cfg.path, '')
                try
                    cs = coffee.compile rawCode
                catch error
                    console.log 'coffee compile error, file:', file, 'error:', error
                finally
                    fs.writeFile file.replace('.coffee', '.js'), cs, (err) ->
                        console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.coffee', '.js'), 'error:', err if err
        else if file.substr(-5) == '.scss'
            sass.render {
                file: file
                success: (css) ->
                    fs.writeFile file.replace('.scss', '.css'), css, (err) ->
                        console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.scss', '.css'), 'error:', err if err
                error: (error) ->
                    console.log('SCSS Compile error:', error);
            }
        else cb()
    parseRoutes: () -> # Parse the already loaded routes.js and create required expressjs routes
        skinny = @
        _.each skinny.routes, (value, key) ->
            method = 'get'
            if typeof value == 'string'
                controller = value.split('#')[0]
                action = value.split('#')[1]
            else if typeof value == 'object'
                controller = value.controller
                action = value.action
                method = value.method if value.method?
            route = true # If no controller or action is defined, just check for the view
            route = false if !skinny.controllers[controller]? or !skinny.controllers[controller][action]?
            skinny.controllers[controller]['*']() if skinny.controllers[controller]? and skinny.controllers[controller]['*']? # Run the catchall function if its defined
            skinny.web[method] key, (req, res) -> # express.js route -> skinny.web is express.app -> we're adding .get, .post... app[method](), etc.
                view = skinny.cfg.layout.views + '/' + controller + '/' + action + '.html'
                ctrlTactic = skinny.controllers[controller][action](req, res) if route
                fs.exists view, (exists) ->
                    res.view = view if exists
                    console.log 'No route for', controller + '#' + action, ' Controllers:', skinny.controllers if !route
                    unless res.headersSent
                        if !ctrlTactic?
                            if exists
                                res.sendfile res.view
                            else
                                res.send '404 - no view'
                        else
                            return if !ctrlTactic
                            ctrlTactic = JSON.stringify ctrlTactic if typeof ctrlTactic == "object"
                            res.send ctrlTactic
    install: () -> # Build a working SkinnyJS project
        skinny = @
        fsCalls = []
        for component, path of skinny.cfg.layout
            fsCalls++
            fs.mkdir path, (err) ->
                return console.log err if err
                if --fsCalls == 0
                    # Development / intro / temporary things - this will be removed and moved into the task runner's init()
                    fs.mkdir skinny.cfg.path + '/app/views/home', (err) ->
                        return console.log err if err
                        skinny.installTemplates()
    installTemplates: () -> # Install templates for a default/preview SkinnyJS project
        skinny = @
        templates = [ '/cfg/routes.js', '/cfg/application.js', '/app/views/home/home.html', '/app/controllers/home.js', '/app/models/thing.js', '/app/assets/socket.io.min.js', '/app/assets/reload.js' ]
        templates.forEach (template) -> fs.createReadStream(__dirname + template).pipe fs.createWriteStream skinny.cfg.path + template
module.exports = Skinnyjs