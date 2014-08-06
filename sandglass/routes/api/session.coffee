express = require 'express'

module.exports = ( app ) ->
  router = express.Router()
    .get '/api/' + app.API_VERSION + '/sessions/:sessionId', ( req, res, next ) ->
      app.models.User.findBySession( req.param( 'sessionId' ) )
        .then( res.success, res.error )
