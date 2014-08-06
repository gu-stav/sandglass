express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .get '/logout', ( req, res, next ) ->
      failed = false
      data = {}

      if not req.cookies?
        failed = true
      else
        session = req.cookies[ app.options.frontend.cookie.name ]

      if not session
        failed = true

      if failed
        return res.status( 403 ).end()

      app.models.User
        .logout( session )
        .then ( user ) ->
          if not user
            throw new Error( 'User was not found' )

          cookieName = app.options.frontend.cookie.name
          res.clearCookie( cookieName )
          res.redirect( '/' )
        .catch ( err ) ->
          app.error( res, err )

  router