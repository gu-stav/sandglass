_ = require( 'lodash' )
express = require( 'express' )
Promise = require( 'bluebird' )

module.exports = ( app ) ->
  express.Router()
    .get app.options.base + '/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.get( req )
        .then( res.success, res.error )

    .get app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.get( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .put app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.update( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .delete app.options.base + '/users/:userId/activities/:activityId', ( req, res, next ) ->
      app.models.Activity.delete( req, req.param( 'activityId' ) )
        .then( res.success, res.error )

    .post app.options.base + '/users/:userId/activities', [ app.sessionAuth ], ( req, res, next ) ->
      app.models.Activity.post( req )
        # set task
        .then ( activity ) ->
          req_clone = _.cloneDeep( req )
          req_clone.body.title = req.body.task or undefined
          activity.addInstance( app.models.Task, req_clone )
        # set activity
        .then ( activity ) ->
          req_clone = _.cloneDeep( req )
          req_clone.body.title = req.body.project or undefined
          activity.addInstance( app.models.Project, req_clone )
        .then( res.success, res.error )
