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

duration = ( start, end ) ->
  if not start or not end
    return

  diff = moment( end ).diff( start )

  if diff > 3600000
    hours = diff / 3600000
    minutes = diff - ( hours * 3600000 ) / 60000

  if diff > 60000
    minutes = diff / 60000
  else
    seconds = diff / 1000

  if hours
    return hours + 'h '
  else
    if minutes
      return parseInt( minutes ) + 'min'
    else
      return parseInt( seconds ) + 'sec'


module.exports =
  duration: duration
  format: format
  fromString: fromString
