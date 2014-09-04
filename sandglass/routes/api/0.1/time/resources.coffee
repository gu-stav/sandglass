errors = require( '../../../../errors/index.coffee' )
express = require( 'express' )
inflection = require( 'inflection' )
Promise = require( 'bluebird' )
url = require( 'url' );

module.exports = ( app ) ->
  express.Router( app.options.base )

    # auth middleware
    .use ( req, res, next ) ->
      action = req.param('action')

      session_ignore = [
        'login',
        'signup',
        'session'
      ]

      # these actions don't require a logged in user - all the others do
      if session_ignore.indexOf( action ) isnt -1
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
          return Promise.reject( errors.BadRequest( err_msg ) )

        # invalid request method
        if action? not app.models[ model_name ][ method ]?
          return Promise.reject( errors.NotImplemented( method ) )

        # invalid action
        if not action? and not app.models[ model_name ][ method ]?
          err_msg = "#{method} not implemented for #{ model_name }"
          return Promise.rejct( errors.BadRequest( err_msg ) )

        # execute given method on the model
        app.models[ model_name ][ method ]( req, req.context, id, res )
          .catch( Promise.reject )
          .then ( instance ) ->
            if instance
              model_name = model_name.toLowerCase()
              req.context[ model_name ] = data[ model_name ] = instance

      # split up the url - forget about get parameters
      parts = url.parse( req.url ).pathname.split( '/' )

      # action: overwrites method
      action = req.param('action')

      # request method
      method = action or req.method.toLowerCase()

      # supported models
      mapping = createModelMapping( app.models )

      # create [ ModelName: #ID (opt.) ] arrray
      promises = createPromiseChain( parts )

      Promise
        .reduce( promises, resolvePromiseChain, 0 )
        .catch( res.error )
        .then( res.finish )