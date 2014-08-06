express = require 'express'

module.exports = ( app ) ->
  express.Router()
    .get app.options.api.base + '/users/:userId/activities', ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.api.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId' ) )
        .then( res.success, res.error )

    .post app.options.api.base +  '/users/:userId/activities', ( req, res, next ) ->
      app.models.User.post( req.body )
        .then( res.success, res.error )
