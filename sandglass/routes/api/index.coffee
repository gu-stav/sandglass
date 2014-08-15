module.exports = ( app ) ->
  login = require( './login.coffee' )( app )
  api_session = require( './session.coffee' )( app )
  api_user = require( './0.1/time/user.coffee' )( app )
  api_activity = require( './0.1/time/activity.coffee' )( app )
  api_task = require( './0.1/time/task.coffee' )( app )

  [ login,
    api_session,
    api_user,
    api_activity,
    api_task, ]