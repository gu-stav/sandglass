module.exports = ( app ) ->
  api_resources = require( './0.1/time/resources.coffee' )( app )

  [ api_resources ]
