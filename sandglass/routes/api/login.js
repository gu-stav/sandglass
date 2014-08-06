// Generated by CoffeeScript 1.7.1
(function() {
  var express;

  express = require('express');

  module.exports = function(app) {
    var router;
    router = express.Router();
    router.post('/api/' + app.API_VERSION + '/login', function(req, res, next) {
      return app.models.User.login(req.body).then((function(_this) {
        return function(user) {
          var renderedUser;
          renderedUser = user.render();
          return res.json(renderedUser);
        };
      })(this))["catch"]((function(_this) {
        return function(err) {
          return app.error(res, err);
        };
      })(this));
    });
    return router;
  };

}).call(this);
