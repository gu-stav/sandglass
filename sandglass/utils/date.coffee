moment = require( 'moment' )
config = require( '../../config-frontend.json' )

getFormat = ( type ) ->
  if not type
    format = config.dateFormatDateTime
  else
    format = config[ 'dateFormat' + type ]

  format

fromString = ( datestr, type ) ->
  if not datestr
    undefined

  format = getFormat( type )

  if not format
    moment.utc( datestr )
  else
    moment( datestr, format )

format = ( date, type ) ->
  if not date
    undefined

  format = getFormat( type )

  if not format
    date.format()
  else
    date.format( format )

module.exports =
  fromString: fromString
  format: format