module.exports = ( app ) ->
  user = require( './user' )( app )

  [ user ]