fs        = require('fs')
path      = require('path')
models    = {}

module.exports = ( db ) ->
  fs
    .readdirSync( __dirname )
    .filter ( file ) ->
      ( file.indexOf( '.' ) isnt 0 ) and
      ( file isnt 'index.js' ) and
      ( file.indexOf( '.js' ) isnt -1 )
    .forEach ( file ) ->
      model = db.import( path.join( __dirname, file ) )
      models[ model.name ] = model

  models
