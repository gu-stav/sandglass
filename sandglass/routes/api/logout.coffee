express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .get app.options.base + '/logout', ( req, res, next ) ->
      app.models.User.logout( req, res )
        .catch( res.error )
        .then( res.success )
