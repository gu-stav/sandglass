_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
prepare_request = require( './utils/prepareapirequest' )
Promise = require( 'bluebird' )
Restclient = require( './utils/restclient' )
Sequelize = require( 'sequelize' )
error_handler = require( './utils/errorhandler' )

class Sandglass
  constructor: ->
    defaults =
      headless: false
      fixtures: process.env.FIXTURES || false
      migrations: process.env.MIGRATIONS || false

    if @.getEnviroment() is 'production'
      defaults.api =
        base: '/api/0.1'
        server:
          port: 3000

      defaults.frontend =
        host: process.env.FRONTEND_HOST
        server:
          port: 3001
        dateFormatDateTime: 'DD.MM.YYYY HH:mm:ss'
        dateFormatDate: 'DD.MM.YYYY'
        dateFormatTime: 'HH:mm'
    else
      defaults.api      = @.getConfig( 'api' )
      defaults.frontend = @.getConfig( 'frontend' )

    @options = defaults

  getEnviroment: () ->
    process.env.NODE_ENV || 'development'

  # read a certain config file
  getConfig: ( index ) ->
    require( '../config-' + index + '.json' )[ @.getEnviroment() ]

  # returns database-connection object
  setupDatabase: () ->
    if @.getEnviroment() is 'production'
      opt =
        name: process.env.DATABASE_NAME
        username: process.env.DATABASE_USER
        password: process.env.DATABASE_PASSWORD
        host: process.env.DATABASE_HOST
        options:
          dialect: 'postgres'
          port: process.env.DATABASE_PORT
    else
      opt = @.getConfig( 'database' )

    console.log( opt )

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
      session = req.cookies.auth or undefined

      sandglass.auth_get( req, res, '?action=session' )
        .catch () ->
          res.redirect( '/signup' )
        .then ( users ) ->
          res.data.user = users.users
          next()

    @mount( app, require( './routes/index' )( app ) )
    return app

  setupAPI: ( app ) ->
    app.options = @options.api

    app.db = @setupDatabase()
    app.models = @setupModels( app.db, app )

    # pretty print the JSON
    if @.getEnviroment() is 'development'
      app.set( 'json spaces', 2 )

    @setupMiddleware( app )

    # initialize the datastore
    app.use( prepare_request )

    # routes
    @mount( app, require( './routes/api/index' )( app ) )

    # error handler
    app.use( error_handler )

    return app

  # Sequelize-Models
  setupModels: ( db, app ) ->
    models = require( './models/index' )( db )

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
      hamster_migrate = require( './hamster-migrate' )

      if @options.migrations
        hamster_migrate( username, password, file )
          .then( resolve, reject )

      resolve( this )

module.exports = Sandglass
