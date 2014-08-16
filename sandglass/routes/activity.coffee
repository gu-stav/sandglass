express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      url = app.options.host + '/users/' + res.data.user.id + '/activities'

      rest.post( url, { data: req.body, headers: req.headers } )
        .on 'complete', ( jres ) ->
          res.redirect( '/' )
