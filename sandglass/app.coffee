_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
Promise = require( 'bluebird' )
rest = require( 'restler' )
Sequelize = require( 'sequelize' )

class Sandglass
  constructor: ( options ) ->
    defaults =
      headless: false
      fixtures: true

      api:
        base: '/api/0.1'
        cookie:
          name: 'auth'
          options:
            expires: new Date( Date.now() + 1000 * 60 * 60 * 24 )
            httpOnly: true
        server:
          port: 3000

      frontend:
        cookie:
          name: 'auth'
          options:
            expires: new Date( Date.now() + 1000 * 60 * 60 * 24 )
            httpOnly: true
        host: 'http://localhost:3000/api/0.1'
        server:
          port: 3001

      db:
        name: ''
        username: 'root'
        password: ''
        host: 'localhost'
        options:
          dialect: 'sqlite'
          storage: 'sandglass.sqlite'

    @options = _.defaults( defaults, options )

  setupDatabase: () ->
    new Sequelize( @options.db.name,
                   @options.db.username,
                   @options.db.password,
                   @options.db.options )

  setupViews: ( app ) ->
    app.set( 'view engine', 'jade' )
    app.set( 'views', __dirname + '/views' )

    app.options = @options.frontend
    @setupMiddleware( app, true )

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
        session = req.cookies[ app.options.cookie.name ]

      if not session
        failed = true

      if failed
        return res.status( 403 ).end()

      rest.get( app.options.host + '/sessions/' + session )
        .on 'complete', ( jres, err ) ->

          if not jres or not jres.users
            return res.status( 403 ).end()

          _.assign( res.data.user, jres.users[ 0 ] )
          next()

    @mount( app, require( './routes/index' )( app ) )
    return app

  setupAPI: ( app ) ->
    app.options = @options.api

    app.db = @setupDatabase( app )
    app.models = @setupModels( app.db )

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
    app.param 'userId', ( req, res, next, userId ) ->
      next()

    @mount( app, require( './routes/api/index' )( app ) )

    # execute response
    app.all '*', ( req, res, next ) ->
      if res.data
        if( res.data.length is 1 )
          res.json( res.data[ 0 ] )
        else
          res.json( res.data )

    return app

  # Sequelize-Models
  setupModels: ( db ) ->
    models = require( './models/index' )( db )

    # automatically create associations between models
    for index, model of models
      if( model.associate? )
        model.associate( models )

    return models

  # Middlewares used by both apps
  setupMiddleware: ( app, url = false ) ->
    if url
      app.use( bodyParser.urlencoded( { extended: true } ) )

    app.use( bodyParser.json() )
    app.use( cookieParser() )

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
          name: 'Testuser'

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
    console.log( @options )
    if not @options.headless
      app_frontend = @setupViews( express() )
      app_frontend.listen( app_frontend.options.server.port )

    app_api = @setupAPI( express() )

    app_api.db.sync()
      .then =>
        console.log( @options )
        if @options.fixtures
          @setupFixtures( app_api )
      .then ->
        app_api.listen( app_api.options.server.port )

module.exports = Sandglass