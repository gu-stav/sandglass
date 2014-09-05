express = require( 'express' )
Restclient = require( '../utils/restclient' )

module.exports = ( app ) ->
  sandglass = new Restclient( app )

  router = express.Router()
    .get '/logout', ( req, res, next ) ->
      sandglass.user_logout_get( req, res, '?action=logout' )
        .spread ( user, raw_response ) ->
          res.redirect( '/signup' )