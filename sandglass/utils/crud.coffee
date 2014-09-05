errors = require( '../errors/index.coffee' )
Promise = require( 'bluebird' )

CREATE = ( data ) ->
  new Promise ( resolve, reject ) =>
    if data and data.defaults and data.where
      @.findOrCreate( find )
        .spread( instance, created ) ->
          resolve( instance, true )
        .catch( reject )
    else
      @.create( data )
        .then ( instance ) ->
          resolve( instance, true )
        .catch( reject )

READ = ( find, id ) ->
  new Promise ( resolve, reject ) =>
    @.findAll( find )
      .then ( instances ) =>
        if id and not instances.length
          return reject( errors.NotFound( @.name ) )

        if id?
          resolve( instances[0] )
        else
          resolve( instances )
      .catch( reject )

module.exports =
  CREATE: CREATE
  READ: READ