_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
Sequelize = require( 'sequelize' )

class Sandglass
  constructor: ( options ) ->
    @defaults =
      headless: false

      server:
        port: 3000

      frontend:
        cookie:
          name: 'auth'
          options:
            expires: new Date( Date.now() + 900000 )
            httpOnly: true

      db:
        name: ''
        username: 'root'
        password: ''
        host: 'localhost'
        options:
          dialect: 'sqlite'
          storage: 'sandglass.sqlite'

    @app = express()
    @app.options = @options = _.defaults( @defaults, options )

  setupDatabase: ->
    @app.db = new Sequelize( @options.db.name,
                             @options.db.username,
                             @options.db.password,
                             @options.db.options )

  setupViews: ->
    @app.set( 'view engine', 'jade' )
    @app.set( 'views', __dirname + '/views' );
    @app.use( bodyParser.urlencoded( { extended: true } ) )

    @mount( require( './routes/index' )( @app ) )

  setupAPI: ->
    @app.API_VERSION = '0.1'
    @mount( require( './routes/api/index' )( @app ) )

    @app.use( bodyParser.json() )

    @app.error = ( res, err ) ->
      console.log( err )
      res.send( err )

  setupModels: ->
    models = require( './models/index' )( @app.db )

    for model in models
      if( model.associate? )
        model.associate( models )

    @app.models = models

  mount: ( routes ) ->
    for router in routes
      @app.use router

  start: () ->
    @setupDatabase()
    @setupModels()

    @app.use( cookieParser() )

    if not @options.headless
      @setupViews()

    @setupAPI()

    @app.db.sync()
      .then =>
        @app.listen @options.server.port

module.exports = Sandglass