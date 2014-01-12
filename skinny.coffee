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
        if !opts.path? then return {} else @path.normalize opts.path
        return unless @path.extname(opts.path) == ".js"
        delete require.cache[require.resolve opts.path] if opts.force?
        # Add the module to skinny - module name is opts.name or the name of the .js file that is loaded
        # We normalize the path, and require it - then pass it (skinny, opts) -> ie: it is assumed the module is a function
        @[type][opts.name or opts.path.split(@path.sep).splice(-1)[0].replace '.js', ''] = require(@path.normalize(opts.path))(@, opts)
    # Skinny project init / server - takes no arguments
    init: () ->
        # Express JS defaults and listen()
        @express    = require 'express'
        @server     = @express()
        @server.use '/views', @express.static @cfg.layout.views
        @server.use '/assets', @express.static @cfg.layout.assets
        @server.use @express.json()
        @httpd      = require('http').createServer @server
        @httpd.listen @cfg.port
        # Socketio init and listen()
        @io         = require('socket.io').listen @httpd, { log: no }
        # MongoDB init and connect() -> adds skinny.db
        require('mongodb').MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, @db) => return console.log @colors.red+'MongoDB error:'+@colors.reset, err if err
        # Load modules!
        [ 'configs', 'controllers', 'models' ].forEach (moduleType) =>
            # Read each modules directory from skinny.cfg.layout
            @fs.readdir @cfg.layout[moduleType], (err, modules) =>
                # For each file in the directory, skinny.initModule() with the correct type and file path
                modules.forEach (path) => @initModule moduleType, { path: @cfg.layout[moduleType]+@path.sep+path }
        # Our socket.io powered quick-reload -> depends on node-watch for cross-platform functionality
        if @cfg.reload
            watch   = require 'node-watch'
            # Common action for files that change
            watchAction = (file) =>
                # Only fires on win32 - ignore changes to directory caught by watch
                return if @fs.lstatSync(file).isDirectory()
                # Make sure file extension isn't a temporary, swap, or version control file
                ext = @path.extname(file)
                return if ext in [ '.tmp', '.swp' ] or file.match @path.sep+'.git'
                # If we have a compiler target matching the extension of the file, fire that off instead of continuing
                return @compiler[ext](file) if @compiler? and @compiler[ext]
                # Load the file! Force a reload of it if it exists already and send a refresh signal to the browser and console
                @initModule file.split(@path.sep).splice(-2)[0], { path: file, force: yes }
                console.log @colors.cyan+'Reloading browser for:'+@colors.reset, file.replace @cfg.path, ''
                @io.sockets.emit('__reload', { delay: 0 })
            # Only watch the app and configs directory for changes
            watch @cfg.layout.app, (file) => watchAction(file)
            watch @cfg.layout.configs, (file) => watchAction(file)
    # Create a new SkinnyJS project template - depends on NCP for code clarity
    # Takes no arguments and copies skinnyjs templates into skinny.cfg.path/
    install: () ->
        fsCalls = 0
        for component, path of @cfg.layout
            fsCalls++
            @fs.mkdir path, (err) =>
                return console.log err if err
                # If this is the last FS mkdir call in the loop
                return unless --fsCalls == 0
                @fs.mkdir @cfg.layout.views + '/home', (err) =>
                    return console.log err if err
                    @fs.mkdir @cfg.layout.assets + '/vendor', (err) =>
                        return console.log err if err
                        require('ncp').ncp(__dirname+dirName, @cfg.path+dirName, (err) -> console.log err if err) for dirName in ['/cfg', '/app']