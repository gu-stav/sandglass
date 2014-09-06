errors = require( '../errors/index' )
Promise = require( 'bluebird' )

create = ( data ) ->
  new Promise ( resolve, reject ) =>
    if data and data.defaults and data.where
      @.findOrCreate( where: data.where )
        .spread ( instance, created ) ->
          resolve( instance, true )
        .catch( reject )
    else
      @.create( data )
        .then ( instance ) ->
          resolve( instance, true )
        .catch( reject )

read = ( find, id ) ->
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

update = ( find, data ) ->
  read.call( @, find, true )
    .catch( Promise.reject )
    .then ( instance ) ->
      instance.updateAttributes( data )
    .catch( Promise.reject )
    .then( Promise.resolve )

destroy = ( find, id ) ->
  read.call( @, find, id )
    .catch( Promise.reject )
    .then ( instance ) ->
      instance.destroy()
    .catch( Promise.reject )

module.exports =
  CREATE: create
  READ: read
  UPDATE: update
  DELETE: destroy
