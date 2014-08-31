BadRequest = ( message, field ) ->
  if message
    @.message = message

  if field
    @.field = field

  @.stack = new Error().stack
  @.code = 400
  @.type = @.name

  return @

BadRequest.prototype = Object.create( Error.prototype )
BadRequest.prototype.name = 'BadRequest'

module.exports = BadRequest;