_ = require( 'lodash' )
express = require( 'express' )
moment = require( 'moment' )
rest = require( 'restler' )

module.exports = ( app ) ->
  DATE_FORMAT = app.options.dateFormat

  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      userId = res.data.user.id
      userSession = res.data.user.session

      data =
        headers: req.headers

      from = req.param( 'from' )
      to = req.param( 'to' )

      if not from
        from = moment().subtract( 1, 'weeks' )
      else
        from = decodeURIComponent( from )
        from = moment.utc( from )

      if not to
        to = moment()
      else
        to = decodeURIComponent( to )
        to = moment.utc( to )

      from_url = encodeURIComponent( from.format() )
      to_url = encodeURIComponent( to.format() )

      get_data = '?from=' + from_url + '&to=' + to_url

      rest
        .get( app.options.host + '/users/' + userId + '/activities' + get_data, data )
        .on 'complete', ( jres, err ) ->
          week_ahead = moment( from ).add( 1, 'weeks' )
          week_back = moment( from ).subtract( 1, 'weeks' )
          today = moment()

          week_back_url = encodeURIComponent( week_back.format() )
          week_ahead_url = encodeURIComponent( week_ahead.format() )

          today_url = encodeURIComponent( today.format() )
          from_url = encodeURIComponent( from.format() )

          template_data =
            title:        'Tracking'
            today:        today.format()
            prev_link:    '/?from=' + week_back_url + '&to=' + today_url
            next_link:    '/?from=' + today_url + '&to=' + week_ahead_url
            showing_from: from.format( DATE_FORMAT )
            showing_to:   to.format( DATE_FORMAT )

          _.assign( res.data, jres, template_data )
          res.render( 'start', res.data )
