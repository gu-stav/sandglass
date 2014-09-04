_ = require( 'lodash' )
errors = require( '../../../../errors/index.coffee' )
express = require( 'express' )
Promise = require( 'bluebird' )
url = require( 'url' );

module.exports = ( app ) ->
  express.Router( app.options.base )
    .use ( req, res, next ) ->
      action = req.param('action')

      if action is 'login' or action is 'signup' or action is 'session'
        return next()

      app.models.User.session( req )
        .then ( user ) ->
          req.user = user
          req.context.user = user
          next()
        .catch ( err ) ->
          res.error( err )
          next()

    .all '*', ( req, res ) ->
      parts = url.parse( req.url ).pathname.split( '/' )

      # supported models
      mapping =
        activities: 'Activity'
        users: 'User'
        tasks: 'Task'
        projects: 'Project'

      promises = []

      # request method
      method = req.method.toLowerCase()

      # action: overwrites method
      action = req.param('action')

      if action
        method = action

      for part, index in parts
        if mapping[ part ]
          model_name = mapping[ part ]
          next_part = parts[ index + 1 ]
          promise_data = [ model_name ]

          if next_part
            # is not a valid model, so must be an identifier
            if not mapping[ next_part ]
              promise_data.push( next_part )

          promises.push( promise_data )

      solvePromises = ( data, promiseData ) ->
        model_name = promiseData[ 0 ]
        id = promiseData[ 1 ]

        if not data
          data = {}

        # invalid model name
        if not app.models[ model_name ]
          err_msg = "#{model_name} not known"
          return Promise.reject( errors.BadRequest( err_msg ) )

        # invalid request method
        if action? not app.models[ model_name ][ method ]?
          return Promise.reject( errors.NotImplemented( method ) )

        # invalid action
        if not action? and not app.models[ model_name ][ method ]?
          err_msg = "#{method} not implemented for #{ model_name }"
          return Promise.rejct( errors.BadRequest( err_msg ) )

        app.models[ model_name ][ method ]( req, req.context, id, res )
          .catch ( err ) ->
            Promise.reject( err )
          .then ( instance ) ->
            if instance
              req.context[ model_name.toLowerCase() ] = instance
              data[ model_name.toLowerCase() ] = instance

      Promise
        .reduce( promises, solvePromises, 0 )
        .catch( res.error )
        .then( res.finish )