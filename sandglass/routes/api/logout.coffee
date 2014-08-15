express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .get app.options.base + '/logout', ( req, res, next ) ->
      app.models.User.logout( req )
        .then( res.success, res.error )
