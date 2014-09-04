errors = require( '../errors/index.coffee' )
Promise = require( 'bluebird' )

READ = ( find, id ) ->
  new Promise ( resolve, reject ) =>
    @.findAll( find )
      .then ( instances ) =>
        if id and not instances.length
          reject( errors.NotFound( @.name ) )

        if id?
          resolve( instances[0] )
        else
          resolve( instances )
      .catch( reject )

module.exports =
  READ: READ