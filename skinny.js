// Generated by CoffeeScript 1.6.3
(function() {
  "use strict";
  var Skinnyjs;

  module.exports = Skinnyjs = (function() {
    function Skinnyjs(cfg) {
      this.cfg = cfg;
      this.path = require('path');
      this._ = require('underscore');
      this.fs = require('fs');
      if (this.cfg == null) {
        this.cfg = {};
      }
      if (this.cfg.port == null) {
        this.cfg.port = 9000;
      }
      if (this.cfg.reload == null) {
        this.cfg.reload = true;
      }
      if (this.cfg.path == null) {
        this.cfg.path = process.cwd();
      }
      if (this.cfg.db == null) {
        this.cfg.db = '127.0.0.1:27017';
      }
      if (this.cfg.project == null) {
        this.cfg.project = this.cfg.path.split('/').splice(-1)[0];
      }
      if (this.cfg.layout == null) {
        this.cfg.layout = {};
      }
      if (this.cfg.layout.app == null) {
        this.cfg.layout.app = this.cfg.path + '/app';
      }
      if (this.cfg.layout.cfg == null) {
        this.cfg.layout.configs = this.cfg.path + '/cfg';
      }
      if (this.cfg.layout.models == null) {
        this.cfg.layout.models = this.cfg.layout.app + '/models';
      }
      if (this.cfg.layout.views == null) {
        this.cfg.layout.views = this.cfg.layout.app + '/views';
      }
      if (this.cfg.layout.controllers == null) {
        this.cfg.layout.controllers = this.cfg.layout.app + '/controllers';
      }
      if (this.cfg.layout.assets == null) {
        this.cfg.layout.assets = this.cfg.layout.app + '/assets';
      }
      this.db = false;
      this.controllers = {};
      this.models = {};
      this.routes = {};
      this.configs = {};
      this.compiler = {};
    }

    Skinnyjs.prototype.initModule = function(type, opts) {
      if (opts.path == null) {
        return {};
      }
      if (this.path.extname(opts.path) !== ".js") {
        return;
      }
      if (opts.force != null) {
        delete require.cache[require.resolve(this.cfg.layout[type] + '/' + opts.path)];
      }
      return this[type][opts.name || opts.path.split('/').splice(-1)[0].replace('.js', '')] = require(this.cfg.layout[type] + '/' + opts.path)(this, opts);
    };

    Skinnyjs.prototype.init = function() {
      var http, mongo, watch, watchAction,
        _this = this;
      http = require('http');
      mongo = require('mongodb').MongoClient;
      this.express = require('express');
      this.socketio = require('socket.io');
      this.server = this.express();
      this.server.use('/views', this.express["static"](this.cfg.layout.views));
      this.server.use('/assets', this.express["static"](this.cfg.layout.assets));
      this.server.use(this.express.json());
      this.httpd = http.createServer(this.server);
      this.httpd.listen(this.cfg.port);
      this.io = this.socketio.listen(this.httpd, {
        log: false
      });
      mongo.connect('mongodb://' + this.cfg.db + '/' + this.cfg.project, function(err, db) {
        _this.db = db;
        if (err) {
          return console.log('MongoDB error:', err);
        }
      });
      ['configs', 'controllers', 'models'].forEach(function(moduleType) {
        return _this.fs.readdir(_this.cfg.layout[moduleType], function(err, modules) {
          return modules.forEach(function(path) {
            return _this.initModule(moduleType, {
              path: path
            });
          });
        });
      });
      if (this.cfg.reload) {
        watch = require('node-watch');
        watchAction = function(file) {
          var ext, path, type;
          ext = _this.path.extname(file);
          if ((ext === '.tmp' || ext === '.swp') || file.match('/.git/')) {
            return;
          }
          if ((_this.compiler != null) && _this.compiler[ext]) {
            return _this.compiler[ext](file);
          }
          if ((function() {
            var _i, _len, _ref, _results;
            _ref = this.cfg.layout;
            _results = [];
            for (path = _i = 0, _len = _ref.length; _i < _len; path = ++_i) {
              type = _ref[path];
              _results.push(file.match(path));
            }
            return _results;
          }).call(_this)) {
            _this.initModule(type, {
              path: path
            });
          }
          console.log('Reloading browser for:', file.replace(_this.cfg.path, ''));
          return _this.io.sockets.emit('__reload', {
            delay: 0
          });
        };
        watch(this.cfg.layout.app, function(file) {
          return watchAction(file);
        });
        return watch(this.cfg.layout.configs, function(file) {
          return watchAction(file);
        });
      }
    };

    Skinnyjs.prototype.install = function() {
      var component, fsCalls, path, _ref, _results,
        _this = this;
      fsCalls = 0;
      _ref = this.cfg.layout;
      _results = [];
      for (component in _ref) {
        path = _ref[component];
        fsCalls++;
        _results.push(this.fs.mkdir(path, function(err) {
          if (err) {
            return console.log(err);
          }
          if (--fsCalls !== 0) {
            return;
          }
          return _this.fs.mkdir(_this.cfg.layout.views + '/home', function(err) {
            if (err) {
              return console.log(err);
            }
            return _this.fs.mkdir(_this.cfg.layout.assets + '/vendor', function(err) {
              if (err) {
                return console.log(err);
              }
              return ['/cfg/routes.coffee', '/cfg/routes.js', '/cfg/compiler.coffee', '/cfg/compiler.js', '/cfg/application.coffee', '/cfg/application.js', '/app/server.js', '/app/views/home/home.html', '/app/controllers/home.coffee', '/app/controllers/home.js', '/app/models/thing.js', '/app/assets/reload.js', '/app/assets/vendor/socket.io.min.js', '/app/assets/vendor/angular.min.js', '/app/assets/vendor/bootstrap.min.css'].forEach(function(template) {
                return _this.fs.createReadStream(__dirname + template).pipe(_this.fs.createWriteStream(_this.cfg.path + template));
              });
            });
          });
        }));
      }
      return _results;
    };

    return Skinnyjs;

  })();

}).call(this);
