_ = require( 'lodash' )
Promise = require( 'bluebird' )

class Controller
  constructor: ( req, res, next ) ->
    @_req = req
    @_res = res
    @_next = next

    @_beforeFilters = []
    @_afterFilters = []

  error: ( err ) =>
    @_next( err )

  render: ( data ) =>
    if @_beforeFilters.length
      Promise.all( @_beforeFilters )
        .catch( @error )
        .then( @_response( data ) )
    else
      @_response( data )

  _response: ( data ) =>
    response = {}
    cookie = @_req.sandglass.data.cookie
    renderer = @_renderer

    if not renderer
      render = 'json'

    if renderer is 'json'
      processDataEntry = ( entry ) ->
        if entry.render?
          processed = entry.render()
        else
          processed = entry.toJSON()

      # returns a pluralform of the model
      getPlural = ( entry ) ->
        entry.__options.name.plural.toLowerCase()

      # returns if an object is a sequelize model
      is_sequelize_model = ( entry ) ->
        return entry.Model or undefined

      # empty response
      if not data
        return @_res.status( 201 ).send().end()

      if _.isArray( data )
        for data_val in data
          if is_sequelize_model( data_val )
            result = processDataEntry( data_val )
            plural = getPlural( data_val )

            if not response[ plural ]
              response[ plural ] = [ result ]
            else
              response[ plural ].push( result )
      else
        if is_sequelize_model( data )
          plural = getPlural( data )
          response[ plural ] = processDataEntry( data )

      if cookie and _.isArray( cookie )
        @_res.cookie( cookie[0], cookie[1], cookie[2] )

      @_res.json( response ).end()

  before: ( promise ) =>
    @_beforeFilters.push( promise( @, @_req, @_res, @_next ) )

class JSONController extends Controller

module.exports =
  Controller: Controller
  JSONController: JSONController
