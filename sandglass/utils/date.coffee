moment = require( 'moment' )
# TODO
config = require( '../../config-frontend.json' ).development

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
    hours = parseInt( diff / 3600000 )
    minutes = parseInt( ( diff - ( hours * 3600000 ) ) / 60000 )
    "#{hours}h #{minutes}min"

  else
    if diff > 60000
      minutes = parseInt( diff / 60000 )
      "#{minutes}min"

    else
      seconds = parseInt( diff / 1000 )
      "#{seconds}sec"

module.exports =
  duration: duration
  format: format
  fromString: fromString
