express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      data =
        data: req.body
      headers:
        'Cookie': 'auth=' + req.user.session

      rest.post( app.options.frontend.host + '/users/' + req.user.id + '/activities', data )
        .on 'complete', ( jres ) ->
          res.redirect( '/' )
