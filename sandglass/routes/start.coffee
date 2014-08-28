_ = require( 'lodash' )
express = require( 'express' )
moment = require( 'moment' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      userId = res.data.user.id
      userSession = res.data.user.session

      data =
        headers: req.headers

      from = moment().subtract( 'months', 1 ).format()
      to = moment().format()

      get_data = '?from=' + from + '&to=' + to

      rest
        .get( app.options.host + '/users/' + userId + '/activities' + get_data, data )
        .on 'complete', ( jres, err ) ->
          _.assign( res.data, jres )
          res.data.title = "Tracking"

          res.render( 'start', res.data )
