express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()

  router
    .get '/logout', ( req, res, next ) ->
      url = app.options.host + '/logout'

      data =
        headers: req.headers

      rest.get( url, data )
        .on 'complete', ( jres, rres ) ->
          res.set( rres.headers )
          res.redirect( '/signup' )

  router