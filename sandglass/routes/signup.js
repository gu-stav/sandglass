// Generated by CoffeeScript 1.7.1
(function() {
  var express;

  express = require('express');

  module.exports = function(app) {
    var router;
    router = express.Router();
    router.get('/signup', function(req, res, next) {
      return res.render('signup');
    }).post('/signup', function(req, res, next) {
      var resp;
      resp = app.models.User.signup(req.body);
      return resp.then(function(user) {
        var renderedUser;
        renderedUser = user.render();
        return res.json(renderedUser);
      })["catch"](function(err) {
        return app.error(err, res);
      });
    });
    return router;
  };

}).call(this);
