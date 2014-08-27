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

    # define basic storage
    app.use ( req, res, next ) ->
      res.data = {}
      next()

    # auth middleware
    app.sessionAuth = ( req, res, next ) =>
      failed = false

      if not req.cookies?
        failed = true
      else
        session = req.cookies[ app.options_api.cookie.name ]

      if not session
        failed = true

      if failed
        return res.status( 403 ).end()

      rest.get( app.options.host + '/sessions/' + session )
        .on 'success', ( jres ) ->
          if not jres or not jres.users
            return res.status( 403 ).end()

          res.data.user = jres.users[ 0 ]
          next()

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
      res.data = []
      # hold collected errors
      res.errors = []
      # success handler
      res.success = ( data ) ->
        if data
          res.data.push( data )
          next()

      # error handler
      res.error = ( err ) ->
        if err
          res.errors.push( err );

        next()
      next()

    # always preload user, when user-id is involved
    app.sessionAuth = ( req, res, next ) ->
      app.models.User.auth( req )
        .then ( users ) ->
          if not users
            return next()

          user = users.users[0]

          if user
            req.user = user
            next()
          else
            res.error( new Error( 'Not auth' ) )

        .catch ( err ) ->
          res.errors.push( err )
          next()

    @mount( app, require( './routes/api/index.coffee' )( app ) )

    # execute response
    app.all '*', ( req, res, next ) ->
      if res.data
        if( res.data.length is 1 )
          res.json( res.data[ 0 ] )
        else
          res.json( res.data )

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
    require( './hamster-migrate.coffee' )( username, password, file )
    return this

module.exports = Sandglass