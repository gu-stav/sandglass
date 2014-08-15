module.exports = ( app ) ->
  login = require( './login.coffee' )( app )
  logout = require( './logout.coffee' )( app )
  start = require( './start.coffee' )( app )
  activity = require( './activity.coffee' )( app )
  signup = require( './signup.coffee' )( app )

  [ login,
    logout,
    start,
    activity,
    signup, ]