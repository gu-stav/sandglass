express = require( 'express' )
Restclient = require( '../utils/restclient.coffee' )

module.exports = ( app ) ->
  sandglass = new Restclient( app )

  router = express.Router()
    .post '/login', ( req, res, next ) ->
      sandglass.user_login_post( req, res, '?action=login' )
        .spread ( user, raw_response ) ->
          res.redirect( '/' )
        .catch ( raw_response ) ->
          raw_response.req = req.body
          res.render( 'signup', raw_response )