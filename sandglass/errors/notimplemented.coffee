NotImplemented = ( method, field ) ->
  @.message = "Method #{method} not implemented"

  if field
    @.field = field

  @.stack = new Error().stack
  @.code = 501
  @.type = @.name

  return @

NotImplemented.prototype = Object.create( Error.prototype )
NotImplemented.prototype.name = 'NotImplemented'

module.exports = NotImplemented;