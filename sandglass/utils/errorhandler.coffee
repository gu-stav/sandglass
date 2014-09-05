error_handler = ( err, req, res, next ) =>
  stack = err.stack
  message = err.message
  status = err.code
  response =
    message: message

  if err.field
    response.field = err.field

  if not message
    message = 'An error occurred'

  if @.getEnviroment() is 'development'
    console.error( err.stack )

  if not status
    status = 500

  res.status( status ).json( errors: [ response ] )

module.exports = error_handler
