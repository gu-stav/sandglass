express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/login', ( req, res, next ) ->
      rest.post( app.options.frontend.host + '/login', data: req.body )
        .on 'complete', ( jres, err ) ->
          user = jres.users[ 0 ]
          session = user.session

          cookieName = app.options.frontend.cookie.name
          cookieOptions = app.options.frontend.cookie.options

          res.cookie( cookieName, session, cookieOptions )
          res.redirect( '/' )