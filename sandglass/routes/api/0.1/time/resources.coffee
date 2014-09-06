{JSONController} = require( '../../../../utils/controller' )
errors = require( '../../../../errors/index' )
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
            req.saveContext( 'user', user )
            req.saveUser( user )

      createModelMapping = ( models ) ->
        result = {}

        for index, model of models
          model_name = model.name
          model_index = inflection.pluralize( model_name )
          model_index = model_index.toLowerCase()

          result[ model_index ] = model_name

        return result

      createPromiseChain = ( url_parts, method ) ->
        result = []

        isChangeMethod = ( method ) ->
          change_methods = [
            'post',
            'put',
            'patch',
            'delete',
          ]

          change_methods.indexOf( method ) isnt -1

        isResource = ( mapping, part ) ->
          mapping[ part ]?

        for part, index in url_parts
          model_name = mapping[ part ]

          if model_name
            next_part = parts[ index + 1 ]
            promise_data = [ model_name ]

            if next_part and
              promise_data.push( [ 'get', 'get' ] )
            else
              promise_data.push( [ method, req_method ] )

            if next_part
              # is not a valid model, so must be an identifier
              if not isResource( mapping, next_part )
                promise_data.push( next_part )

            result.push( promise_data )

        # if the request will change data, only apply it to the last resource
        if isChangeMethod( method )
          [ ..., last ] = result
          last[ 1 ][ 0 ] = method
          last[ 1 ][ 1 ] = req_method

        return result

      resolvePromiseChain = ( data, promise_data ) ->
        model_name = promise_data[ 0 ]
        local_request_object = promise_data[ 1 ]
        id = promise_data[ 2 ]

        local_action = local_request_object[ 0 ]
        local_request_method = local_request_object[ 1 ]

        # first run
        if not data
          data = {}

        # invalid model name
        if not app.models[ model_name ]
          err_msg = "#{model_name} not known"
          return Promise.reject( new errors.BadRequest( err_msg ) )

        Model = app.models[ model_name ]

        if Model.actionSupported? and not
           Model.actionSupported( local_action, local_request_method )
          return Promise.reject( new errors.NotImplemented( local_action ) )

        # invalid request method
        if action? not Model[ local_action ]?
          return Promise.reject( new errors.NotImplemented( local_action ) )

        if local_request_method is 'post'
          promise = Model[ local_action ]( req, req.sandglass.context, res )
        else
          promise = Model[ local_action ]( req, req.sandglass.context, id, res )

        promise
          .catch( Promise.reject )
          .then ( instance ) ->
            if instance
              model_name = model_name.toLowerCase()
              req.saveContext( model_name, instance )
              data[ model_name ] = instance

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
      promises = createPromiseChain( parts, method )

      controller = new JSONController( req, res, next )
      controller.before( auth_user )

      Promise
        .reduce( promises, resolvePromiseChain, 0 )
        .catch( controller.error )
        .then( controller.render )
