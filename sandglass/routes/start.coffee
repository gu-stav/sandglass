_ = require( 'lodash' )
date = require( '../utils/date.coffee' )
decode = require( '../utils/url.coffee' ).decode
encode = require( '../utils/url.coffee' ).encode
express = require( 'express' )
moment = require( 'moment' )
rest = require( 'restler' )

module.exports = ( app ) ->
  DATE_FORMAT = app.options.dateFormat

  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      userId = res.data.user.id
      userSession = res.data.user.session

      if not req.param( 'from' )
        from = moment().subtract( 1, 'weeks' )
      else
        from = date.fromString( decode( req.param( 'from' ) ), 'Date' )

      if not req.param( 'to' )
        to = moment()
      else
        to = date.fromString( decode( req.param( 'to' ) ), 'Date' )

      data =
        headers: req.headers

      get_data = '?from=' + encode( date.format( from ) ) +
                 '&to=' + encode( date.format( to ) )

      rest
        .get( app.options.host + '/users/' + userId + '/activities' + get_data, data )
        .on 'complete', ( jres, err ) ->

          week_ahead = to.clone().add( 1, 'weeks' )
          week_ahead_start = to.clone()

          week_back = from.clone().subtract( 1, 'weeks' )
          week_back_end = from.clone()

          week_back_url = date.format( week_back, 'Date' )
          week_back_end_url = date.format( week_back_end, 'Date' )

          week_ahead_url = date.format( week_ahead, 'Date' )
          week_ahead_start_url = date.format( week_ahead_start, 'Date' )

          template_data =
            title:        'Tracking'
            prev_link:    '/?from=' + encode( week_back_url ) +
                          '&to=' + encode( week_back_end_url )
            next_link:    '/?from=' + encode( week_ahead_start_url ) +
                          '&to=' + encode( week_ahead_url )
            showing_from: date.format( from, 'Date' )
            showing_to:   date.format( to, 'Date' )

          if jres.activities? and jres.activities.length
            activities = _.groupBy jres.activities, ( activity ) ->
              return date.format( moment( activity.start ), 'Date' )

            for groupName, groupActivities of activities
              for activity in groupActivities
                if activity.start
                  activity._start = activity.start
                  activity_start = moment( activity.start )
                  activity.start = date.format( activity_start, 'Time' )

                if activity.end
                  activity._end = activity.end
                  activity_end = moment( activity.end )
                  activity.end = date.format( activity_end, 'Time' )

                if activity.end
                  activity_duration_end = activity_end
                else
                  activity_duration_end = moment()

                activity.duration = date.duration( activity_start,
                                                   activity_duration_end )
          else
            activities= {}

          _.assign( res.data,
                    activities: activities,
                    template_data )

          res.render( 'start', res.data )
