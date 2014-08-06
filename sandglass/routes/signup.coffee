express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/signup', ( req, res, next ) ->
      res.render 'signup'

    .post '/signup', ( req, res, next ) ->
      rest.post( app.options.frontend.host + '/users', data: req.body )
        .on 'complete', ( jres, err ) ->
          res.redirect( '/signup' )
