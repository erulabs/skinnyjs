"use strict";
module.exports = class Skinnyjs
    constructor: (@cfg) ->
        @path                   = require 'path'
        @_                      = require 'underscore'
        @fs                     = require 'fs'
        @cfg = {} if !@cfg? # Configuration defaults
        @cfg.port               = 9000 unless @cfg.port?
        @cfg.reload             = true unless @cfg.reload?
        @cfg.db                 = '127.0.0.1:27017' unless @cfg.db?
        @cfg.dil                = if (require('os').platform() == 'win32') then "\\" else '/'
        @cfg.path               = @path.normalize process.cwd() unless @cfg.path?
        @cfg.project            = @cfg.path.split(@cfg.dil).splice(-1)[0] unless @cfg.project?
        @cfg.layout             = {} unless @cfg.layout?
        @cfg.layout.app         = @cfg.path + '/app' unless @cfg.layout.app?
        @cfg.layout.configs     = @cfg.path + '/cfg' unless @cfg.layout.cfg?
        @cfg.layout.models      = @cfg.layout.app + '/models' unless @cfg.layout.models?
        @cfg.layout.views       = @cfg.layout.app + '/views' unless @cfg.layout.views?
        @cfg.layout.controllers = @cfg.layout.app + '/controllers' unless @cfg.layout.controllers?
        @cfg.layout.assets      = @cfg.layout.app + '/assets' unless @cfg.layout.assets?
        @db = false; @controllers = {}; @models = {}; @routes = {}; @configs = {}; @compiler = {};
    initModule: (type, opts) ->
        return {} if !opts.path?
        return unless @path.extname(opts.path) == ".js"
        delete require.cache[require.resolve @cfg.layout[type]+'/'+opts.path] if opts.force?
        @[type][opts.name or opts.path.split('/').splice(-1)[0].replace '.js', ''] = require(@cfg.layout[type]+'/'+opts.path)(@, opts)
    init: () ->
        http        = require 'http'
        @express    = require 'express'
        @server     = @express()
        @server.use '/views', @express.static @cfg.layout.views
        @server.use '/assets', @express.static @cfg.layout.assets
        @server.use @express.json()
        @httpd      = http.createServer @server
        @httpd.listen @cfg.port
        @io         = require('socket.io').listen @httpd, { log: no }
        require('mongodb').MongoClient.connect 'mongodb://'+@cfg.db+'/'+@cfg.project, (err, @db) => return console.log 'MongoDB error:', err if err
        [ 'configs', 'controllers', 'models' ].forEach (moduleType) =>
            @fs.readdir @cfg.layout[moduleType], (err, modules) =>
                modules.forEach (path) => @initModule moduleType, { path }
        if @cfg.reload
            watch   = require 'node-watch'
            watchAction = (file) =>
                ext = @path.extname(file)
                return if ext in [ '.tmp', '.swp' ] or file.match '/.git/'
                return @compiler[ext](file) if @compiler? and @compiler[ext]
                @initModule type, { path: path } if file.match path for type, path in @cfg.layout
                console.log 'Reloading browser for:', file.replace @cfg.path, ''
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
                        require('ncp').ncp(__dirname + dirName, @cfg.path + dirName, (err) -> console.log err if err) for dirName in ['/cfg', '/app']
    copyDir: (from, to, recursive) ->
        from = [ from ] if typeof from == 'string'
        from.forEach (fromDir) ->
