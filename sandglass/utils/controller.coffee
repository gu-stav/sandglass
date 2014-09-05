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

    if not @_renderer
      processDataEntry = ( entry ) ->
        if entry.Model?
          if entry.render?
            processed = entry.render()
          else
            processed = entry.toJSON()

      if _.isArray( data )
        for data_val in data
          if data_val.Model
            result = processDataEntry( data_val )
            data_val_index = data_val.__options.name.plural.toLowerCase()

            if not response[ data_val_index ]
              response[ data_val_index ] = [ result ]
            else
              response[ data_val_index ].push( result )

      else
        if data and data.__options
          response[ data.__options.name.plural.toLowerCase() ] = processDataEntry( data )

      if @_req.sandglass.data.cookie
        @_res.cookie( @_req.sandglass.data.cookie[0],
                     @_req.sandglass.data.cookie[1],
                     @_req.sandglass.data.cookie[2] )

      @_res.json( response ).end()

  before: ( promise ) =>
    @_beforeFilters.push( promise( @, @_req, @_res, @_next ) )

class JSONController extends Controller

module.exports =
  Controller: Controller
  JSONController: JSONController
