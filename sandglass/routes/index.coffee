module.exports = ( app ) ->
  login = require( './login' )( app )
  logout = require( './logout' )( app )
  start = require( './start' )( app )
  activity = require( './activity' )( app )
  signup = require( './signup' )( app )

  [ login,
    logout,
    start,
    activity,
    signup, ]