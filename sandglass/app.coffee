_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
Promise = require( 'bluebird' )
rest = require( 'restler' )
Sequelize = require( 'sequelize' )

class Sandglass
  constructor: ->
    defaults =
      headless: false
      fixtures: process.env.FIXTURES || false
      migrations: process.env.MIGRATIONS || false

    defaults.api      = require( '../config-api.json' )
    defaults.frontend = require( '../config-frontend.json' )
    defaults.db       = require( '../config-database.json' )

    defaults.api.cookie.options.expires =
        new Date( Date.now() + parseInt( defaults.api.cookie.options.expires ) )

    @options = defaults

  setupDatabase: () ->
    new Sequelize( @options.db.name,
                   @options.db.username,
                   @options.db.password,
                   @options.db.options )

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

      res.error = ( err ) ->
        if err
          res.errors.push( err )

        next()

      next()

    # auth middleware
    app.sessionAuth = ( req, res, next ) =>
      session = req.cookies[ app.options_api.cookie.name ] or undefined

      rest.get( app.options.host + '/sessions/' + session )
        .on 'complete', ( jres ) ->
          if jres.users
            res.data.user = jres.users[ 0 ]
            next()
          else
            res.redirect( '/signup' )

    @mount( app, require( './routes/index.coffee' )( app ) )
    return app

  setupAPI: ( app ) ->
    app.options = @options.api

    app.db = @setupDatabase( app )
    app.models = @setupModels( app.db, app )

    @setupMiddleware( app )

    # initialize response object
    app.use ( req, res, next ) ->
      # hold collected data
      res.data = {}
      # hold collected errors
      res.errors = []
      # success handler
      res.success = ( data ) ->
        if data
          _.assign( res.data, data )

        next()

      # error handler
      res.error = ( err ) ->
        if err
          res.errors.push( err );

        next()

      req.getSessionCookie = () ->
        req.cookies[ app.options.cookie.name ] or undefined

      next()

    # always preload user, when user-id is involved
    app.sessionAuth = ( req, res, next ) ->
      app.models.User.auth( req )
        .then ( user ) ->
          req.user = user
          next()
        .catch ( err ) ->
          res.error( err )

    @mount( app, require( './routes/api/index.coffee' )( app ) )

    # execute response
    app.all '*', ( req, res, next ) ->
      if res.errors and res.errors.length > 0
        res.data.errors = []

        _.each res.errors, ( err ) ->
          if err.field?
            errData =
              field: err.field

          if err.message?
            if _.isObject( errData )
              errData.message = err.message
            else
              errData = err.message

          res.data.errors.push( errData )

        res.status( 400 )

      res.json( res.data ).end()

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
    new Promise ( resolve, reject ) =>
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
        .then ( role ) =>
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
