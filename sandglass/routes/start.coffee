_ = require( 'lodash' )
express = require( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      #rest
      #  .get( app.options.host + '/users/' + req.user.id + '/activities' )
      #  .on 'complete', ( jres, err )
      #    _.assign( res.data, jres )
      res.data.activities = []
      res.render( 'start', res.data )
