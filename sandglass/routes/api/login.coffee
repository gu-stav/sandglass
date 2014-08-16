express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .post app.options.base + '/login', ( req, res, next ) ->
      app.models.User.login( req, res )
        .then( res.success, res.error )
