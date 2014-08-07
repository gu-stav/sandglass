express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      data =
        data: req.body
      headers:
        'Cookie': 'auth=' + res.data.user.session

      rest.post( app.options.host + '/users/' + res.data.user.id + '/activities', data )
        .on 'complete', ( jres ) ->
          res.redirect( '/' )
