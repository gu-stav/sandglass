express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/api/' + app.API_VERSION + '/login', ( req, res, next ) ->
      app.models.User.login( req )
        .then( res.success, res.error )
