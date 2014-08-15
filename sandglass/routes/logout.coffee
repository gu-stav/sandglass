express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()

  router
    .get '/logout', [ app.sessionAuth ], ( req, res, next ) ->
      url = app.options.host + '/users/' + res.data.user.id + '/activities'

      rest.get( url )
        .on 'complete', ( jres ) ->
          cookieName = app.options.cookie.name
          res.clearCookie( cookieName )
          res.redirect( '/signup' )

  router