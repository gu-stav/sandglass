NotFound = ( resourceName, field ) ->
  @.message = 'Resource #{resourceName} not found'

  if field
    @.field = field

  @.stack = new Error().stack
  @.code = 404
  @.type = @.name

  return @

NotFound.prototype = Object.create( Error.prototype )
NotFound.prototype.name = 'NotFound'

module.exports = NotFound;