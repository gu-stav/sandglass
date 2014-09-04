_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
Promise = require( 'bluebird' )
Restclient = require( './utils/restclient.coffee' )
Sequelize = require( 'sequelize' )

class Sandglass
  constructor: ->
    defaults =
      headless: false
      fixtures: process.env.FIXTURES || false
      migrations: process.env.MIGRATIONS || false

    defaults.api      = @.getConfig( 'api' )
    defaults.frontend = @.getConfig( 'frontend' )

    defaults.api.cookie.options.expires =
        new Date( Date.now() + parseInt( defaults.api.cookie.options.expires ) )

    @options = defaults

  getEnviroment: () ->
    process.env.ENVIROMENT || 'development'

  # read a certain config file
  getConfig: ( index ) ->
    require( '../config-' + index + '.json' )[ @.getEnviroment() ]

  # returns database-connection object
  setupDatabase: ( opt ) ->
    new Sequelize( opt.name,
                   opt.username,
                   opt.password,
                   opt.options )

  setupViews: ( app ) =>
    app.options = @options.frontend
    app.options_api = @options.api

    @setupMiddleware( app )

    app.set( 'view engine', 'jade' )
    app.set( 'views', __dirname + '/views' )
    app.use( express.static( __dirname + '/static' ) )

    # define basic storage
    app.use ( req, res, next ) ->
      res.data = {}
      res.errors = []

      res.getUser = () ->
        res.data.user

      res.error = ( err ) ->
        if err
          res.errors.push( err )

        next()

      next()

    # auth middleware
    app.sessionAuth = ( req, res, next ) =>
      sandglass = new Restclient( app )
      session = req.cookies[ app.options_api.cookie.name ] or undefined

      sandglass.auth_get( req, res, '?action=session' )
        .catch () ->
          res.redirect( '/signup' )
        .then ( users ) ->
          res.data.user = users.users
          next()

    @mount( app, require( './routes/index.coffee' )( app ) )
    return app

  setupAPI: ( app ) ->
    app.options = @options.api

    app.db = @setupDatabase( @.getConfig( 'database' ) )
    app.models = @setupModels( app.db, app )

    if @.getEnviroment() is 'development'
      app.set( 'json spaces', 2 )

    @setupMiddleware( app )

    # initialize response object
    app.use ( req, res, next ) ->
      # hold collected data
      res.data = {}
      # hold collected errors
      res.errors = []

      req.context = {}

      # success handler
      res.finish = ( data ) ->
        response = {}

        processDataEntry = ( entry ) ->
          res_data = {}

          if entry.Model?
            if entry.render?
              processed = entry.render()
            else
              processed = entry.toJSON()

        if res.errors.length
          response.errors = []

          for error in res.errors
            if error.field
              err_data =
                field: error.field
                message: error.message

              response.errors.push( err_data )
            else
              response.errors.push( error.message )

        if _.isArray( data )
          for data_val in data
            if data_val.Model
              result = processDataEntry( data_val )
              data_val_index = data_val.__options.name.plural.toLowerCase()

              if not response[ data_val_index ]
                response[ data_val_index ] = [ result ]
              else
                response[ data_val_index ].push( result )

        else
          if data
            response[ data.__options.name.plural.toLowerCase() ] = processDataEntry( data )

        if res.data.cookie
          res.cookie( res.data.cookie[0], res.data.cookie[1], res.data.cookie[2] )

        res.json( response ).end()

      # error handler
      res.error = ( err ) ->
        response = {}

        if err
          res.errors.push( err )

        if res.errors.length
          response.errors = []

          for error in res.errors
            if error.field
              err_data =
                field: error.field
                message: error.message

              response.errors.push( err_data )
            else
              response.errors.push( error.message )

        res.json( response ).status( err.code ).end()

      req.getSessionCookie = () ->
        req.cookies[ app.options.cookie.name ] or undefined

      next()

    @mount( app, require( './routes/api/index.coffee' )( app ) )

    return app

  # Sequelize-Models
  setupModels: ( db, app ) ->
    models = require( './models/index.coffee' )( db )

    # automatically create associations between models
    for index, model of models
      if( model.associate? )
        model.associate( models, app )

    return models

  # Middlewares used by both apps
  setupMiddleware: ( app ) ->
    app.use( cookieParser() )

    app.use( bodyParser.urlencoded( { extended: true } ) )
    app.use( bodyParser.json() )

  # API-Fixtures
  setupFixtures: ( app )->
    new Promise ( resolve, reject ) ->
      role =
        body:
          name: 'Admin'
          default: true
          admin: true

      user =
        body:
          email: 'gustavpursche@gmail.com'
          _rawPassword: 'test'
          name: 'Test User'

      app.models.Role
        .post( role )
        .then ( role ) ->
          app.models.User.post( user )
        .then( resolve, reject )

  # mount express.Router()
  mount: ( app, routes ) ->
    for router in routes
      app.use router

  # start application
  start: () ->
    new Promise ( resolve, reject ) =>
      if not @options.headless
        app_frontend = @setupViews( express() )
        app_frontend.listen( app_frontend.options.server.port )

      app_api = @setupAPI( express() )

      app_api.db.sync()
        .then =>
          if @options.fixtures
            @setupFixtures( app_api )
        .then =>
          app_api.listen( app_api.options.server.port )
          resolve( this )

  migrate: ( username, password, file ) ->
    new Promise ( resolve, reject ) =>
      hamster_migrate = require( './hamster-migrate.coffee' )

      if @options.migrations
        hamster_migrate( username, password, file )
          .then( resolve, reject )

      resolve( this )

module.exports = Sandglass
