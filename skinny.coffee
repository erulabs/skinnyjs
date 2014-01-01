# Skinny.js by Seandon 'erulabs' Mooy -> admin@erulabs.com -> github.com/erulabs
#     _______  __  ___  __   __   __   __   __  ____    ____        __       ______
#    /       ||  |/  / |  | |  \ |  | |  \ |  | \   \  /   /       |  |     /      |
#   |   (----`|  '  /  |  | |   \|  | |   \|  |  \   \/   /        |  |    |   (---`
#    \   \    |    <   |  | |    `  | |    `  |   \_    _/   .--.  |  |     \   \    
#|----)   |   |     \  |  | |  |\   | |  |\   |     |  |  __ |  `--'  | .----)   |   
#|_______/    |__|\__\ |__| |__| \__| |__| \__|     |__| (__) \______/  |_______/    
# A micro ORM-less Javascript MVC Framework that makes your MVC look fat
"use strict";
# SkinnyJS requirements:
fs      = require 'fs'
http    = require 'http'
mongo   = require('mongodb').MongoClient
_       = require 'underscore'
# Development only requirements:
watch   = require 'node-watch'
coffee  = require 'coffee-script'
sass    = require 'node-sass'
# Console colors for logging
colors  = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" }
class Skinnyjs
    constructor: (@cfg) ->
        # Configuration defaults
        @cfg = {} if !@cfg?
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
        # Initialize Skinny components
        @db             = false
        @controllers    = {}
        @models         = {}
        @routes         = {}
    # Skinny Controller
    Controller: (skinny, name, controller) ->
        controller skinny
    # Skinny Model
    Model: (skinny, name, model) ->
        instance = model skinny
        collection = skinny.db.collection(name)
        instance.prototype.find = (opts) ->
            collection.find(opts)
        instance.prototype.all = (cb) ->
            collection.find().toArray (err, instances) ->
                console.log 'MongoDB error on ' + name + '.all():', err if err
                cb(instances)
        return instance
    # Initialize a SkinnyJS application
    init: (cb) ->
        skinny = @
        lazyLoad = 0
        # Read and init
        fs.readdir skinny.cfg.layout.controllers, (err, controllers) ->
            controllers.forEach (controllerPath) ->
                return unless controllerPath.indexOf '.js' > -1
                name = controllerPath.replace '.js', ''
                controller = require skinny.cfg.layout.controllers + '/' + controllerPath
                skinny.controllers[name] = new skinny.Controller skinny, name, controller
                cb() if ++lazyLoad == 2
        fs.readdir skinny.cfg.layout.models, (err, models) ->
            models.forEach (modelPath) ->
                return unless modelPath.indexOf '.js' > -1
                name = modelPath.replace '.js', ''
                model = require skinny.cfg.layout.models + '/' + modelPath
                skinny.models[name] = new skinny.Model skinny, name, model
                cb() if ++lazyLoad == 2
    # SkinnyJS services wrapper
    server: () ->
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
        
        @web.set 'port', @cfg.port
        @autoreload() if @cfg.reload
        @httpd.listen @cfg.port
        @io = @socketio.listen @httpd, { log: no }

        @io.sockets.on 'connections', (socket) ->
            # Do something with sockets
        mongo.connect 'mongodb://' + @cfg.db + '/' + @cfg.project, (err, db) ->
            return console.log 'MongoDB error:', err if err
            skinny.db = db
            skinny.init () ->
                skinny.parseRoutes()
    # Watch the project directory and reload the browser when required. Also calls compileAsset() on things like coffeescript
    autoreload: () ->
        skinny = @
        watch @cfg.layout.app, (file) ->
            compile = skinny.compileAsset file
            if !compile
                console.log colors.cyan+'browser reloading:'+colors.reset, file.replace(skinny.cfg.path, '')
                skinny.io.sockets.emit '__reload', { delay: 0 }
    # Todo: A more robust asset compiler, with support for far more things.
    # this should be called primary from autoreload, but also on a static call of "compile all assets" from the script runner
    # it should handle 
    compileAsset: (file) ->
        skinny = @
        fs.exists file, (exists) ->
            return unless exists
            # This ought to check against an array of compilable assets
            # and use node path's extention checker
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
                        console.log 'writing css', css
                        fs.writeFile file.replace('.scss', '.css'), css, (err) ->
                            console.log colors.red+'autocompile write error! file'+colors.reset, file.replace('.scss', '.css'), 'error:', err if err
                    error: (error) ->
                        console.log('SCSS Compile error:', error);
                }
            else
                return false

    # Parse the already loaded routes.js and create required expressjs routes
    parseRoutes: () ->
        skinny = @
        _.each skinny.routes, (value, key) ->
            if typeof value == 'string'
                controller = value.split('#')[0]
                action = value.split('#')[1]
                method = 'GET'
            else if typeof value == 'object'
                controller = value.controller
                action = value.action
                if value.method?
                    method = value.method
                else
                    method = 'GET'
            # If no controller or action is defined, just check for the view
            route = true
            route = false if !skinny.controllers[controller]? or !skinny.controllers[controller][action]?
            if skinny.controllers[controller]?
                skinny.controllers[controller]['*']() if skinny.controllers[controller]['*']?
            skinny.web[method.toLowerCase()] key, (req, res) ->
                view = skinny.cfg.layout.views + '/' + controller + '/' + action + '.html'
                #console.log 'rendering', view.replace(skinny.cfg.path, '')
                fs.exists view, (exists) ->
                    if exists
                        res.view = view
                        if route
                            ctrlTactic = skinny.controllers[controller][action] req, res
                        else
                            console.log 'No route for', controller + '#' + action, ' Controllers:', skinny.controllers
                        unless res.headersSent
                            if !ctrlTactic?
                                res.sendfile res.view
                            else
                                ctrlTactic = JSON.parse ctrlTactic if typeof ctrlTactic == "object"
                                res.send ctrlTactic
                    else
                        res.send '404 - no view'

    # Build a working SkinnyJS project
    install: () ->
        @installDirectoryLayout()
    # Build the directory structure of a SkinnyJS project
    installDirectoryLayout: () ->
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
    # Install templates for a default/preview SkinnyJS project
    installTemplates: () ->
        skinny = @
        templates = [
            '/cfg/routes.js'
            '/app/views/home/home.html'
            '/app/controllers/home.js'
            '/app/models/thing.js'
            '/app/assets/socket.io.min.js'
            '/app/assets/reload.js' ]
        templates.forEach (template) ->
            from = __dirname + template
            to = skinny.cfg.path + template
            fs.createReadStream(from).pipe fs.createWriteStream to


module.exports = Skinnyjs