express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .get '/', ( req, res, next ) ->
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
        .findBySession( session )
        .then ( user ) ->
          if not user
            throw new Error( 'User was not found' )

          data = user.render()
          req.user = user

          app.models.Activity.get( req )
            .then ( activities ) ->
              data.activities = activities
              res.render( 'start', data )
        .catch ( err ) ->
          app.error( res, err )

  router