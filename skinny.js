// Generated by CoffeeScript 1.6.3
(function() {
  "use strict";
  var Skinnyjs, coffee, colors, fs, http, mongo, sass, watch, _;

  fs = require('fs');

  http = require('http');

  mongo = require('mongodb').MongoClient;

  _ = require('underscore');

  watch = require('node-watch');

  coffee = require('coffee-script');

  sass = require('node-sass');

  colors = {
    red: "\u001b[31m",
    blue: "\u001b[34m",
    green: "\u001b[32m",
    cyan: "\u001b[36m",
    reset: "\u001b[0m"
  };

  Skinnyjs = (function() {
    function Skinnyjs(cfg) {
      this.cfg = cfg;
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
        this.cfg.layout.cfg = this.cfg.path + '/cfg';
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
    }

    Skinnyjs.prototype.Controller = function(skinny, name, controller) {
      return controller(skinny);
    };

    Skinnyjs.prototype.Model = function(skinny, name, model) {
      var collection, instance;
      instance = model(skinny);
      collection = skinny.db.collection(name);
      instance.prototype.find = function(opts) {
        return collection.find(opts);
      };
      instance.prototype.all = function(cb) {
        return collection.find().toArray(function(err, instances) {
          if (err) {
            console.log('MongoDB error on ' + name + '.all():', err);
          }
          return cb(instances);
        });
      };
      return instance;
    };

    Skinnyjs.prototype.init = function(cb) {
      var lazyLoad, skinny;
      skinny = this;
      lazyLoad = 0;
      fs.readdir(skinny.cfg.layout.controllers, function(err, controllers) {
        return controllers.forEach(function(controllerPath) {
          if (!skinny.initController(controllerPath)) {
            return;
          }
          if (++lazyLoad === 2) {
            return cb();
          }
        });
      });
      return fs.readdir(skinny.cfg.layout.models, function(err, models) {
        return models.forEach(function(modelPath) {
          if (!skinny.initModel(modelPath)) {
            return;
          }
          if (++lazyLoad === 2) {
            return cb();
          }
        });
      });
    };

    Skinnyjs.prototype.initController = function(controllerPath) {
      var controller, name;
      if (controllerPath.substr(-3) !== '.js') {
        return false;
      }
      name = controllerPath.replace('.js', '');
      controller = require(this.cfg.layout.controllers + '/' + controllerPath);
      if (this.controllers[name] != null) {
        delete require.cache[require.resolve(this.cfg.layout.controllers + '/' + controllerPath)];
      }
      return this.controllers[name] = new this.Controller(this, name, controller);
    };

    Skinnyjs.prototype.initModel = function(modelPath) {
      var model, name;
      if (modelPath.substr(-3) !== '.js') {
        return false;
      }
      name = modelPath.replace('.js', '');
      model = require(this.cfg.layout.models + '/' + modelPath);
      return this.models[name] = new this.Model(this, name, model);
    };

    Skinnyjs.prototype.server = function() {
      var overrides, skinny;
      skinny = this;
      this.express = require('express');
      this.socketio = require('socket.io');
      this.web = this.express();
      this.web.use('/views', this.express["static"](this.cfg.layout.views));
      this.web.use('/assets', this.express["static"](this.cfg.layout.assets));
      this.web.use(this.express.json());
      this.httpd = http.createServer(this.web);
      this.routes = require(this.cfg.layout.cfg + '/routes.js');
      overrides = require(this.cfg.layout.cfg + '/application.js');
      overrides(this);
      this.web.set('port', this.cfg.port);
      if (this.cfg.reload) {
        this.autoreload();
      }
      this.httpd.listen(this.cfg.port);
      this.io = this.socketio.listen(this.httpd, {
        log: false
      });
      this.io.sockets.on('connections', function(socket) {});
      return mongo.connect('mongodb://' + this.cfg.db + '/' + this.cfg.project, function(err, db) {
        if (err) {
          return console.log('MongoDB error:', err);
        }
        skinny.db = db;
        return skinny.init(function() {
          return skinny.parseRoutes();
        });
      });
    };

    Skinnyjs.prototype.autoreload = function() {
      var skinny;
      skinny = this;
      return watch(this.cfg.path, function(file) {
        if (file.match('/.git/')) {
          return;
        }
        return skinny.compileAsset(file, function() {
          if (file.match('/controllers/')) {
            console.log(colors.cyan + 'rebuilding controller:' + colors.reset, file.replace(skinny.cfg.layout.controllers + '/', ''));
            skinny.initController(file.replace(skinny.cfg.layout.controllers + '/', ''));
          }
          if (file.match('/cfg/')) {
            if (file.match('application.js')) {
              console.log(colors.green + 'rebuilding config:' + colors.reset, '/cfg/application.js');
              delete require.cache[require.resolve(file)];
              skinny.server();
            } else if (file.match('routes.js')) {
              console.log(colors.green + 'rebuilding config:' + colors.reset, '/cfg/routes.js');
              delete require.cache[require.resolve(file)];
              skinny.routes = require(file);
            } else {
              console.log(colors.red + 'Non-standard /cfg/ file changed - not reloading. Server probably needs a restart!' + colors.reset);
            }
          }
          console.log(colors.cyan + 'browser reloading:' + colors.reset, file.replace(skinny.cfg.path, ''));
          return skinny.io.sockets.emit('__reload', {
            delay: 0
          });
        });
      });
    };

    Skinnyjs.prototype.compileAsset = function(file, cb) {
      var skinny;
      skinny = this;
      if (file.substr(-7) === '.coffee') {
        return fs.readFile(file, 'utf8', function(err, rawCode) {
          var cs, error;
          if (err) {
            console.log(colors.red + 'autoreload readfile error:' + colors.reset, err);
          }
          console.log(colors.cyan + 'autocompiling coffeescript:' + colors.reset, file.replace(skinny.cfg.path, ''));
          try {
            return cs = coffee.compile(rawCode);
          } catch (_error) {
            error = _error;
            return console.log('coffee compile error, file:', file, 'error:', error);
          } finally {
            fs.writeFile(file.replace('.coffee', '.js'), cs, function(err) {
              if (err) {
                return console.log(colors.red + 'autocompile write error! file' + colors.reset, file.replace('.coffee', '.js'), 'error:', err);
              }
            });
          }
        });
      } else if (file.substr(-5) === '.scss') {
        return sass.render({
          file: file,
          success: function(css) {
            return fs.writeFile(file.replace('.scss', '.css'), css, function(err) {
              if (err) {
                return console.log(colors.red + 'autocompile write error! file' + colors.reset, file.replace('.scss', '.css'), 'error:', err);
              }
            });
          },
          error: function(error) {
            return console.log('SCSS Compile error:', error);
          }
        });
      } else {
        return cb();
      }
    };

    Skinnyjs.prototype.parseRoutes = function() {
      var skinny;
      skinny = this;
      return _.each(skinny.routes, function(value, key) {
        var action, controller, method, route;
        if (typeof value === 'string') {
          controller = value.split('#')[0];
          action = value.split('#')[1];
          method = 'GET';
        } else if (typeof value === 'object') {
          controller = value.controller;
          action = value.action;
          if (value.method != null) {
            method = value.method;
          } else {
            method = 'GET';
          }
        }
        route = true;
        if ((skinny.controllers[controller] == null) || (skinny.controllers[controller][action] == null)) {
          route = false;
        }
        if (skinny.controllers[controller] != null) {
          if (skinny.controllers[controller]['*'] != null) {
            skinny.controllers[controller]['*']();
          }
        }
        return skinny.web[method.toLowerCase()](key, function(req, res) {
          var view;
          view = skinny.cfg.layout.views + '/' + controller + '/' + action + '.html';
          return fs.exists(view, function(exists) {
            var ctrlTactic;
            if (exists) {
              res.view = view;
            }
            if (route) {
              ctrlTactic = skinny.controllers[controller][action](req, res);
            } else {
              console.log('No route for', controller + '#' + action, ' Controllers:', skinny.controllers);
            }
            if (!res.headersSent) {
              if (ctrlTactic == null) {
                if (exists) {
                  return res.sendfile(res.view);
                } else {
                  return res.send('404 - no view');
                }
              } else {
                if (typeof ctrlTactic === "object") {
                  ctrlTactic = JSON.parse(ctrlTactic);
                }
                return res.send(ctrlTactic);
              }
            }
          });
        });
      });
    };

    Skinnyjs.prototype.install = function() {
      return this.installDirectoryLayout();
    };

    Skinnyjs.prototype.installDirectoryLayout = function() {
      var component, fsCalls, path, skinny, _ref, _results;
      skinny = this;
      fsCalls = [];
      _ref = skinny.cfg.layout;
      _results = [];
      for (component in _ref) {
        path = _ref[component];
        fsCalls++;
        _results.push(fs.mkdir(path, function(err) {
          if (err) {
            return console.log(err);
          }
          if (--fsCalls === 0) {
            return fs.mkdir(skinny.cfg.path + '/app/views/home', function(err) {
              if (err) {
                return console.log(err);
              }
              return skinny.installTemplates();
            });
          }
        }));
      }
      return _results;
    };

    Skinnyjs.prototype.installTemplates = function() {
      var skinny, templates;
      skinny = this;
      templates = ['/cfg/routes.js', '/cfg/application.js', '/app/views/home/home.html', '/app/controllers/home.js', '/app/models/thing.js', '/app/assets/socket.io.min.js', '/app/assets/reload.js'];
      return templates.forEach(function(template) {
        var from, to;
        from = __dirname + template;
        to = skinny.cfg.path + template;
        return fs.createReadStream(from).pipe(fs.createWriteStream(to));
      });
    };

    return Skinnyjs;

  })();

  module.exports = Skinnyjs;

}).call(this);
