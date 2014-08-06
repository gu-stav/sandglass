express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .post '/api/' + app.API_VERSION + '/login', ( req, res, next ) ->
      app.models.User.login( req.body )
        .then ( user ) =>
          renderedUser = user.render()
          res.json( renderedUser )
        .catch ( err ) =>
          app.error( res, err )

  router