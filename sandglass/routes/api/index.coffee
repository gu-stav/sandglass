_ = require 'lodash'

module.exports = ( app ) ->
  login = require( './login' )( app )
  signup = require( './signup' )( app )
  time = require( './time/index' )( app )

  # require auth on every url, which contains the userId-Parameter
  app.param 'userId', ( req, res, next, id ) ->
    app.models.User.load( id )
      .then ( user ) =>
        if not user
          return res.status( 403 ).end()

        req.user = user
        next()

  [ login, signup ]