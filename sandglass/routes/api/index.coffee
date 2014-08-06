module.exports = ( app ) ->
  login = require( './login' )( app )
  api_session = require( './session' )( app )
  api_user = require( './0.1/time/user' )( app )
  api_activity = require( './0.1/time/activity' )( app )

  [ login,
    api_session,
    api_user,
    api_activity, ]