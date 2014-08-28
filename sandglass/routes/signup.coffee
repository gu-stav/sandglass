express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/signup', ( req, res, next ) ->
      res.data.title = "Signup"

      res.render( 'signup', res.data )

    .post '/signup', ( req, res, next ) ->
      rest.post( app.options.host + '/users', data: req.body )
        .on 'complete', ( jres, err ) ->
          res.redirect( '/signup' )
