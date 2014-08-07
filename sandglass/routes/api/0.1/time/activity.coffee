express = require( 'express' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/activities', ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities', ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.get( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities', ( req, res, next ) ->
      app.models.Activity.post( req.body )
        .then( res.success, res.error )
