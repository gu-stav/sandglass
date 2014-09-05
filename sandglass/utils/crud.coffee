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
          return reject( new errors.NotFound( @.name ) )

        if id?
          resolve( instances[0] )
        else
          resolve( instances )
      .catch( reject )

UPDATE = ( find, data ) ->
  READ( find )
    .catch( Promise.reject )
    .then ( instance ) =>
      instance.updateAttributes( data )
    .catch( Promise.reject )

DELETE = ( find, id ) ->
  READ( find, id )
    .catch( Promise.reject )
    .then ( instance ) =>
      instance.destroy()
    .catch( Promise.reject )

module.exports =
  CREATE: CREATE
  READ: READ
  UPDATE: UPDATE
  DELETE: DELETE
