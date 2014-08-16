_ = require( 'lodash' )
express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      userId = res.data.user.id
      userSession = res.data.user.session

      data =
        headers: req.headers

      rest
        .get( app.options.host + '/users/' + userId + '/activities', data )
        .on 'complete', ( jres, err ) ->
          _.assign( res.data, jres )
          res.render( 'start', res.data )
