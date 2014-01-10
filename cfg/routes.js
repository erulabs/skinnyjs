// Generated by CoffeeScript 1.6.3
(function() {
  module.exports = function(app) {
    app.routes = {
      '/': {
        controller: 'home',
        action: 'home'
      },
      '/somePost': {
        method: 'post',
        controller: 'home',
        action: 'somePost'
      }
    };
    app.parseRoutes = function() {
      return app._.each(app.routes, function(obj, route) {
        return app.server[obj.method || 'get'](route, function(req, res) {
          var controllerOutput;
          if (app.controllers[obj.controller]['*'] != null) {
            app.controllers[obj.controller]['*'](req, res);
          }
          console.log('(' + req.connection.remoteAddress + ')', req.method + ':', req.url, obj.controller + '#' + obj.action);
          res.view = app.cfg.layout.views + '/' + obj.controller + '/' + obj.action + '.html';
          controllerOutput = app.controllers[obj.controller][obj.action](req, res);
          if (controllerOutput != null) {
            if (res.headersSent || !controllerOutput) {
              return;
            }
            if (typeof controllerOutput === "object") {
              controllerOutput = JSON.stringify(controllerOutput);
            }
            return res.send(controllerOutput);
          } else {
            return res.sendfile(res.view);
          }
        });
      });
    };
    return app.parseRoutes();
  };

}).call(this);
