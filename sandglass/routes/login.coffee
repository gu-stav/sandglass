express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  router
    .post '/login', ( req, res, next ) ->
      app.models.User.login( req.body )
        .then ( user ) ->
          renderedUser = user.render().user
          session = renderedUser.session

          cookieName = app.options.frontend.cookie.name
          cookieOptions = app.options.frontend.cookie.options

          res.cookie( cookieName, session, cookieOptions )
          res.redirect( '/' )
        .catch ( err ) ->
          app.error( res, err )

  router