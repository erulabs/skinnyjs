// Generated by CoffeeScript 1.7.1
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
    return app.parseRoutes();
  };

}).call(this);
