express = require( 'express' )
moment = require( 'moment' )
Promise = require( 'bluebird' )
rest = require( 'restler' )
Restclient = require( '../utils/restclient' )

module.exports = ( app ) ->
  sandglass = new Restclient( app )

  router = express.Router()
    .post '/activity', [ app.sessionAuth ], ( req, res, next ) ->
      createActivity = () ->
        sandglass.activity_post( req, res )
          .then ( data ) ->
            data.activities

      createTask = ( activity ) ->
        data =
          body:
            title: req.body.task
          headers: req.headers

        sandglass.activity_task_post( activity.id, data, res )
          .then ( data ) ->
            data.tasks

      createProject = ( activity ) ->
        data =
          body:
            title: req.body.project
          headers: req.headers

        sandglass.activity_project_post( activity.id, data, res )
          .then ( data ) ->
            data.projects

      createActivity()
        .then ( activity ) ->
          createTask( activity )
            .then ( task ) ->
              return activity

        .then ( activity ) ->
          createProject( activity )
            .then ( project ) ->
              return activity

        .then () ->
          res.redirect( 'back' )

    .post '/activity/:activityId/stop', [ app.sessionAuth ], ( req, res, next ) ->
      data =
        body:
          end: moment().format()
        headers: req.headers

      sandglass.activity_put( req.param( 'activityId' ), data, res )
        .then ( activity ) ->
          res.redirect( 'back' )

    .post '/activity/:activityId/delete', [ app.sessionAuth ], ( req, res, next ) ->
      data =
        headers: req.headers

      sandglass.activity_delete( req.param( 'activityId' ), data, res )
        .then ( activity ) ->
          res.redirect( 'back' )
