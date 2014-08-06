express = require ( 'express' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      data =
        user: req.user
        activities: []

      rest.get( app.options.frontend.host + '/users/' + req.user.id + '/activities' )
        .on 'complete', ( jres, err )
          data.activities = jres.activities

          res.render( 'start', data )
