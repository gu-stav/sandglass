express = require( 'express' )
rest = require( 'restler' )
moment = require( 'moment' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      url = app.options.host + '/users/' + res.data.user.id + '/activities'

      rest.post( url, { data: req.body, headers: req.headers } )
        .on 'complete', ( jres ) ->
          res.redirect( '/' )

    .post '/activity/:activityId/stop', [ app.sessionAuth ], ( req, res, next ) ->
      activityId = req.param( 'activityId' )
      url = app.options.host + '/users/' + res.data.user.id + '/activities/' + activityId

      data =
        data:
          end: moment().format()
        headers: req.headers

      rest.put( url, data )
        .on 'complete', ( jres ) ->
          res.redirect( 'back' )

    .post '/activity/:activityId/delete', [ app.sessionAuth ], ( req, res, next ) ->
      activityId = req.param( 'activityId' )
      url = app.options.host + '/users/' + res.data.user.id + '/activities/' + activityId

      data =
        headers: req.headers

      rest.del( url, data )
        .on 'complete', ( jres ) ->
          res.redirect( 'back' )
