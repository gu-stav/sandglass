JSONController = require( '../../../../utils/controller.coffee' ).JSONController
errors = require( '../../../../errors/index.coffee' )
express = require( 'express' )
inflection = require( 'inflection' )
Promise = require( 'bluebird' )
url = require( 'url' );

module.exports = ( app ) ->
  express.Router( app.options.base )
    .all '*', ( req, res, next ) ->
      auth_user = ( controller, req, res ) ->
        action = req.param('action')

        session_ignore = [
          'login',
          'signup',
          'session'
        ]

        # these actions don't require a logged in user - all the others do
        if session_ignore.indexOf( action ) isnt -1
          return Promise.resolve()

        app.models.User.session( req )
          .catch( controller.error )
          .then ( user ) ->
            req.sandglass.context.user = req.sandglass.user = user

      createModelMapping = ( models ) ->
        result = {}

        for index, model of models
          model_name = model.name
          model_index = inflection.pluralize( model_name )
          model_index = model_index.toLowerCase()

          result[ model_index ] = model_name

        return result

      createPromiseChain = ( url_parts ) ->
        result = []

        for part, index in url_parts
          model_name = mapping[ part ]

          if model_name
            next_part = parts[ index + 1 ]
            promise_data = [ model_name ]

            if next_part
              # is not a valid model, so must be an identifier
              if not mapping[ next_part ]
                promise_data.push( next_part )

            result.push( promise_data )

        return result

      resolvePromiseChain = ( data, promiseData ) ->
        model_name = promiseData[ 0 ]
        id = promiseData[ 1 ]

        # first run
        if not data
          data = {}

        # invalid model name
        if not app.models[ model_name ]
          err_msg = "#{model_name} not known"
          return Promise.reject( new errors.BadRequest( err_msg ) )

        if app.models[ model_name ].actionSupported? and not
           app.models[ model_name ].actionSupported( method, req_method )
          return Promise.reject( new errors.NotImplemented( req_method ) )

        # invalid request method
        if action? not app.models[ model_name ][ method ]?
          return Promise.reject( new errors.NotImplemented( req_method ) )

        # invalid action
        if not action? and not app.models[ model_name ][ method ]?
          err_msg = "#{method} not implemented for #{ model_name }"
          return Promise.rejct( new errors.BadRequest( err_msg ) )

        Model = app.models[ model_name ]

        if method is 'post'
          promise = app.models[ model_name ][ method ]( req, req.sandglass.context, res )
        else
          promise = app.models[ model_name ][ method ]( req, req.sandglass.context, id, res )

        promise
          .catch( Promise.reject )
          .then ( instance ) ->
            if instance
              model_name = model_name.toLowerCase()
              req.sandglass.context[ model_name ] = data[ model_name ] = instance

      # split up the url - forget about get parameters
      parts = url.parse( req.url ).pathname.split( '/' )

      req_method = req.method.toLowerCase()

      # action: overwrites method
      action = req.param('action')

      # request method
      method = action or req_method

      # supported models
      mapping = createModelMapping( app.models )

      # create [ ModelName: #ID (opt.) ] arrray
      promises = createPromiseChain( parts )

      controller = new JSONController( req, res, next )
      controller.before( auth_user )

      Promise
        .reduce( promises, resolvePromiseChain, 0 )
        .catch( controller.error )
        .then( controller.render )
