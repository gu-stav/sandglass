module.exports = ( app ) ->
  login = require( './login' )( app )
  logout = require( './logout' )( app )
  start = require( './start' )( app )
  signup = require( './signup' )( app )

  [ login, logout, start, signup ]