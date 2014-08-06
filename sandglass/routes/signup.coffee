express = require( 'express' )

module.exports = ( app ) ->
  router = express.Router()

  router
    .get '/signup', ( req, res, next ) ->
      res.render 'signup'

    .post '/signup', ( req, res, next ) ->
      app.models.User.post( req.body )
        .then ( user ) ->
          renderedUser = user.render()
          res.json( renderedUser )
        .catch ( err ) ->
          app.error( err, res )

  router