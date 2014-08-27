express = require( 'express' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.get( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .put app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.update( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.post( req )
        .then( res.success, res.error )
