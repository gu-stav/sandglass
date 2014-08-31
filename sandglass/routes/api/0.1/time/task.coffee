express = require( 'express' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/tasks', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Task.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/tasks', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId') )
        .then ( user ) ->
          app.models.Task.get( req, user )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/tasks/:taskId', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Task.get( req, req.param( 'taskId' ) )
        .then( res.success, res.error )
