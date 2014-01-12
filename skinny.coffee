module.exports = class Skinnyjs
    constructor: (@cfg) ->
        @path                   = require 'path'
        @_                      = require 'underscore'
        @fs                     = require 'fs'
        @cfg = {} if !@cfg? # Configuration defaults
        @cfg.port               = 9000 unless @cfg.port?
        @cfg.reload             = true unless @cfg.reload?
        @cfg.db                 = '127.0.0.1:27017' unless @cfg.db?
        @cfg.path               = @path.normalize process.cwd() unless @cfg.path?
        @cfg.project            = @cfg.path.split(@path.sep).splice(-1)[0] unless @cfg.project?
        @cfg.layout             = { app: '/app', configs: '/cfg', models: '/app/models', views: '/app/views', controllers: '/app/controllers', assets: '/app/assets' } unless @cfg.layout?
        @cfg.layout[key]        = @path.normalize(@cfg.path + @cfg.layout[key]) for key, value of @cfg.layout
        @colors                 = { red: "\u001b[31m", blue: "\u001b[34m", green: "\u001b[32m", cyan: "\u001b[36m", reset: "\u001b[0m" }
        @db = false; @controllers = {}; @models = {}; @routes = {}; @configs = {}; @compiler = {};
    initModule: (type, opts) ->
        if !opts.path? then return {} else @path.normalize opts.path
        return unless @path.extname(opts.path) == ".js"
        delete require.cache[require.resolve @cfg.layout[type]+'/'+opts.path] if opts.force?
        @[type][opts.name or opts.path.split('/').splice(-1)[0].replace '.js', ''] = require(@path.normalize(@cfg.layout[type]+'/'+opts.path))(@, opts)
    init: () ->
        @express    = require 'express'
        @server     = @express()
        @server.use '/views', @express.static @cfg.layout.views
        @server.use '/assets', @express.static @cfg.layout.assets
        @server.use @express.json()
        @httpd      = require('http').createServer @server
        @httpd.listen @cfg.port
        @io         = require('socket.io').listen @httpd, { log: no }
        require('mongodb').MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, @db) => return console.log @colors.red+'MongoDB error:'+@colors.reset, err if err
        [ 'configs', 'controllers', 'models' ].forEach (moduleType) =>
            @fs.readdir @cfg.layout[moduleType], (err, modules) =>
                modules.forEach (path) => @initModule moduleType, { path }
        if @cfg.reload
            watch   = require 'node-watch'
            watchAction = (file) =>
                return if @fs.lstatSync(file).isDirectory()
                ext = @path.extname(file)
                return if ext in [ '.tmp', '.swp' ] or file.match @path.sep+'.git'
                return @compiler[ext](file) if @compiler? and @compiler[ext]
                @initModule type, { path: path, force: yes } if file.match path for type, path in @cfg.layout
                console.log @colors.cyan+'Reloading browser for:'+@colors.reset, file.replace @cfg.path, ''
                @io.sockets.emit('__reload', { delay: 0 })
            watch @cfg.layout.app, (file) => watchAction(file)
            watch @cfg.layout.configs, (file) => watchAction(file)
    install: () ->
        fsCalls = 0
        for component, path of @cfg.layout
            fsCalls++
            @fs.mkdir path, (err) =>
                return console.log err if err
                return unless --fsCalls == 0
                @fs.mkdir @cfg.layout.views + '/home', (err) =>
                    return console.log err if err
                    @fs.mkdir @cfg.layout.assets + '/vendor', (err) =>
                        return console.log err if err
                        require('ncp').ncp(__dirname+dirName, @cfg.path+dirName, (err) -> console.log err if err) for dirName in ['/cfg', '/app']