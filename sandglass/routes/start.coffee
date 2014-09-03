_ = require( 'lodash' )
date = require( '../utils/date.coffee' )
decode = require( '../utils/url.coffee' ).decode
encode = require( '../utils/url.coffee' ).encode
express = require( 'express' )
moment = require( 'moment' )
Promise = require( 'bluebird' )
rest = require( 'restler' )
Restclient = require( '../utils/restclient.coffee' )

module.exports = ( app ) ->
  sandglass = new Restclient( app )
  DATE_FORMAT = app.options.dateFormat

  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      userId = res.data.user.id

      if not req.param( 'from' )
        from = moment().subtract( 1, 'weeks' )
      else
        from = date.fromString( decode( req.param( 'from' ) ), 'Date' )

      if not req.param( 'to' )
        to = moment()
      else
        to = date.fromString( decode( req.param( 'to' ) ), 'Date' )

      req_data = headers: req.headers

      get_data = '?from=' + encode( date.format( from ) ) +
                 '&to=' + encode( date.format( to ) )

      getActivities = () ->
        sandglass.user_activities_get( req, res, get_data )
          .then ( data ) ->
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

            if data.activities? and data.activities.length
              data.activities = _.groupBy data.activities, ( activity ) ->
                return date.format( moment( activity.start ), 'Date' )

              for groupName, groupActivities of data.activities
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
              data.activities= []

            _.assign( data, template_data )

      getTasks = ( data ) ->
        sandglass.user_tasks_get( req, res, get_data )
          .then ( rdata ) ->
            if not rdata or not rdata.tasks
              rdata.tasks = []

            _.assign( data, rdata )

      getProjects = ( data ) ->
        sandglass.user_projects_get( req, res, get_data )
          .then ( rdata ) ->
            if not rdata or not rdata.projects
              rdata.projects = []

            _.assign( data, rdata )

      getActivities()
        .then( getTasks )
        .then( getProjects )
        .then ( data ) ->
          _.assign( res.data, data )
          res.render( 'start', res.data )
