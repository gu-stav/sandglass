module.exports = ( app ) ->
  api_resources = require( './0.1/time/resources' )( app )

  [ api_resources ]
