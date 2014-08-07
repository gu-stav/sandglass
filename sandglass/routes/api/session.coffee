express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .get app.options.base + '/sessions/:sessionId', ( req, res, next ) ->
      app.models.User.findBySession( req.param( 'sessionId' ) )
        .then( res.success, res.error )
