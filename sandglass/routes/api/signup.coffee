express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .post '/api/' + app.API_VERSION + '/signup', ( req, res, next ) ->
      app.models.User.signup( req.body )
        .then ( user ) =>
          renderedUser = user.render()
          res.json( renderedUser )
        .catch ( err ) =>
          app.error( res, err )

  router