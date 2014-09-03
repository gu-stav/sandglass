express = require( 'express' )
moment = require( 'moment' )
Promise = require( 'bluebird' )
rest = require( 'restler' )

module.exports = ( app ) ->
  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      createActivity = () ->
        url =  "#{app.options.host}/users/#{res.data.user.id}/activities"

        new Promise ( resolve, reject ) ->
          rest.post( url, { data: req.body, headers: req.headers } )
            .on 'complete', ( result ) ->
              resolve( result.activities[ 0 ] )

      createTask = ( activity ) ->
        url = "#{app.options.host}/users/#{res.data.user.id}/activities/#{activity.id}/tasks"

        data =
          title: req.body.task

        new Promise ( resolve, reject ) ->
          rest.post( url, { data: data, headers: req.headers } )
            .on 'complete', ( result ) ->
              resolve( result.tasks )

      createProject = ( activity ) ->
        url = "#{app.options.host}/users/#{res.data.user.id}/activities/#{activity.id}/projects"

        data =
          title: req.body.project

        new Promise ( resolve, reject ) ->
          rest.post( url, { data: data, headers: req.headers } )
            .on 'complete', ( result ) ->
              resolve( result.projects )

      createActivity()
        .then ( activity ) ->
          new Promise ( resolve, reject ) ->
            createTask( activity )
              .then ( task ) ->
                resolve( activity )
        .then ( activity ) ->
          new Promise ( resolve, reject ) ->
            createProject( activity )
              .then ( project ) ->
                resolve( activity )
        .then () ->
          res.redirect( 'back' )

    .post '/activity/:activityId/stop', [ app.sessionAuth ], ( req, res, next ) ->
      activityId = req.param( 'activityId' )
      url = "#{app.options.host}/users/#{res.data.user.id}/activities/#{activityId}"

      data =
        data:
          end: moment().format()
        headers: req.headers
      console.log(url)
      rest.put( url, data )
        .on 'complete', ( jres ) ->
          res.redirect( 'back' )

    .post '/activity/:activityId/delete', [ app.sessionAuth ], ( req, res, next ) ->
      activityId = req.param( 'activityId' )
      url = "#{app.options.host}/users/#{res.data.user.id}/activities/#{activityId}"

      data =
        headers: req.headers

      rest.del( url, data )
        .on 'complete', ( jres ) ->
          res.redirect( 'back' )
