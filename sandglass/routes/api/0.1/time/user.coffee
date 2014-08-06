express = require 'express'

module.exports = ( app ) ->
  router = express.Router()

  listUsers = ( req, res, next ) ->
    app.models.user.signup( req )

  router
    .get( '/users', listUsers )

  router