express = require( 'express' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/tags', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Tag.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/tags', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Tag.get( req, user )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/tasks/:tagId', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Tag.get( req, user, req.param( 'tagId' ) )
        .then( res.success, res.error )
