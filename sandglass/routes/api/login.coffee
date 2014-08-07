express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .post app.options.base + '/login', ( req, res, next ) ->
      console.log( req.body )
      app.models.User.login( req )
        .then( res.success, res.error )
