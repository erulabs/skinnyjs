(function() {
  module.exports = function(app) {
    var coffee, less, sass;
    sass = false;
    coffee = false;
    less = false;
    app.compiler['.coffee'] = function(file, callback) {
      var error;
      try {
        require.resolve('coffee-script');
      } catch (_error) {
        error = _error;
        return app.log(app.clr.cyan + 'CoffeeScript:' + app.clr.reset, 'not installed - try npm install "coffee-script"');
      }
      if (!coffee) {
        coffee = require('coffee-script');
      }
      return app.fs.readFile(file, 'utf8', (function(_this) {
        return function(err, rawCode) {
          var cs;
          if (err) {
            app.log(app.clr.red + 'compileAsset() error:' + app.clr.reset, err);
          }
          app.log(app.clr.cyan + 'CoffeeScript:' + app.clr.reset, file.replace(app.cfg.path, ''));
          try {
            cs = coffee.compile(rawCode);
          } catch (_error) {
            error = _error;
            return app.log(app.clr.red + 'CoffeeScript error:' + app.clr.reset, file.replace(app.cfg.path, '') + ':', error.message, error.description, error);
          }
          if (error == null) {
            return app.fs.writeFile(file.replace('.coffee', '.js'), cs, function(err) {
              if (err) {
                app.log(app.clr.red + 'autocompile write error! file' + app.clr.reset, file.replace('.coffee', '.js'), 'error:', err);
                if (callback != null) {
                  return callback(false);
                }
              } else {
                if (callback != null) {
                  return callback(file);
                }
              }
            });
          }
        };
      })(this));
    };
    app.compiler['.scss'] = function(file, callback) {
      var error;
      try {
        require.resolve('node-sass');
      } catch (_error) {
        error = _error;
        return app.log(app.clr.cyan + 'SASS:' + app.clr.reset, 'not installed - try npm install "node-sass"');
      }
      if (!sass) {
        sass = require('node-sass');
      }
      app.log(app.clr.cyan + 'SASS:' + app.clr.reset, file.replace(app.cfg.path, ''));
      return sass.render({
        file: file,
        success: (function(_this) {
          return function(css) {
            app.fs.writeFile(file.replace('.scss', '.css'), css, function(err) {
              if (err) {
                return app.log(app.clr.red + 'autocompile write error! file' + app.clr.reset, file.replace('.scss', '.css'), 'error:', err);
              }
            });
            if (callback != null) {
              return callback(file);
            }
          };
        })(this),
        error: (function(_this) {
          return function(error) {
            app.log(app.clr.red + 'SCSS Compile error:' + app.clr.reset, error);
            if (callback != null) {
              return callback(false);
            }
          };
        })(this)
      });
    };
    return app.compiler['.less'] = function(file, callback) {
      var error;
      try {
        require.resolve('less');
      } catch (_error) {
        error = _error;
        return app.log(app.clr.cyan + 'LESS:' + app.clr.reset, 'not installed - try npm install "less"');
      }
      if (!less) {
        less = require('less');
      }
      app.log(app.clr.cyan + 'LESS:' + app.clr.reset, file.replace(app.cfg.path, ''));
      return less.render(app.fs.readFileSync(file, 'utf8'), function(err, css) {
        return app.fs.writeFile(file.replace('.less', '.css'), css, function(err) {
          if (err) {
            app.log(app.clr.red + 'autocompile write error! file' + app.clr.reset, file.replace('.less', '.css'), 'error:', err);
            if (callback != null) {
              return callback(false);
            }
          } else {
            if (callback != null) {
              return console.log(file);
            }
          }
        });
      });
    };
  };

}).call(this);
