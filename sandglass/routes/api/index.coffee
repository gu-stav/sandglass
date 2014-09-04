module.exports = ( app ) ->
  login = require( './login.coffee' )( app )
  logout = require( './logout.coffee' )( app )
  api_session = require( './session.coffee' )( app )
  api_resources = require( './0.1/time/resources.coffee' )( app )

  [ login,
    logout,
    api_resources ]