express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .post '/activity', ( req, res, next ) ->
      app.models.Activity.post( req )
        .then ->
          res.redirect( '/' )

  router