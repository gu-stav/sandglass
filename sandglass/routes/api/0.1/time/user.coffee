express = require 'express'

module.exports = ( app ) ->
  express.Router()
    .get app.options.api.base + '/users', ( req, res, next ) ->
      app.models.User.get( req )
        .then( res.success, res.error )

    .get app.options.api.base + '/users/:userId', ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId' ) )
        .then( res.success, res.error )

    .post app.options.api.base + '/users', ( req, res, next ) ->
      console.log( req.body )
      app.models.User.post( req )
        .then( res.success, res.error )
