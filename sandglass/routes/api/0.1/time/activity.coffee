_ = require( 'lodash' )
express = require( 'express' )
Promise = require( 'bluebird' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.get( req, req.user )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Activity.get( req, user )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Activity.get( req, user: user, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .put app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Activity.update( req, user: user, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .delete app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Activity.delete( req, user: user, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param( 'userId'), single: true )
        .then ( user ) ->
          app.models.Activity.post( req, user: user )
            .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities/:activityId/tasks', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param('userId' ), single: true )
        .then ( user ) ->
          new Promise ( resolve, reject ) ->
            app.models.Activity.get( req, user: user, req.param( 'activityId' ) )
              .then ( activities ) ->
                resolve( { activity: activities.activities[ 0 ], user: user } )
        .then ( context ) ->
          app.models.Task.post( req, context )
        .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities/:activityId/projects', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.User.get( req, req.param('userId' ), single: true )
        .then ( user ) ->
          new Promise ( resolve, reject ) ->
            app.models.Activity.get( req, user: user, req.param( 'activityId' ) )
              .then ( activities ) ->
                resolve( { activity: activities.activities[ 0 ], user: user } )
        .then ( context ) ->
          app.models.Project.post( req, context )
        .then( res.success, res.error )
