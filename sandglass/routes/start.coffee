_ = require( 'lodash' )
date = require( '../utils/date' )
decode = require( '../utils/url' ).decode
encode = require( '../utils/url' ).encode
express = require( 'express' )
moment = require( 'moment' )
Promise = require( 'bluebird' )
Restclient = require( '../utils/restclient' )

module.exports = ( app ) ->
  sandglass = new Restclient( app )

  router = express.Router()
    .get '/', [ app.sessionAuth ], ( req, res, next ) ->
      if not req.param( 'from' )
        from = moment().subtract( 1, 'weeks' )
      else
        from = date.fromString( decode( req.param( 'from' ) ), 'Date' )

      if not req.param( 'to' )
        to = moment()
      else
        to = date.fromString( decode( req.param( 'to' ) ), 'Date' )

      req_data = headers: req.headers

      get_data =
        from: encode( date.format( from ) )
        to: encode( date.format( to ) )

      getTemplateData = () ->
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

      getActivities = () ->
        sandglass.user_activities_get( req, res, get_data )
          .then ( data ) ->
            if not data.activities? or not data.activities.length
              return data.activities= []

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

            return data

      getTasks = () ->
        sandglass.user_tasks_get( req, res )

      getProjects = () ->
        sandglass.user_projects_get( req, res )

      # join seems to be more performant, than promise.all
      Promise.join( getActivities(), getTasks(), getProjects() )
        .spread ( activities_data, tasks_data, projects_data ) ->

          data =
            activities: activities_data.activities or []
            tasks: tasks_data.tasks or []
            projects: projects_data.projects or []

          _.assign( res.data, data, getTemplateData() )
          res.render( 'start', res.data )
