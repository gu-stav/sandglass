express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/login', ( req, res, next ) ->
      rest.post( app.options.host + '/login', data: req.body )
        .on 'success', ( jres, rres ) ->
          res.set( rres.headers )
          res.redirect( '/' )