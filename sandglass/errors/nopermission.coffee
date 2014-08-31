NoPermission = ( message ) ->
  if message
    @.message = message

  @.stack = new Error().stack
  @.code = 403
  @.type = @.name

  return @

NoPermission.prototype = Object.create( Error.prototype )
NoPermission.prototype.name = 'NoPermission'

module.exports = NoPermission;