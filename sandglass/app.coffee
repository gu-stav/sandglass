_ = require( 'lodash' )
bodyParser = require( 'body-parser')
cookieParser = require('cookie-parser')
express = require( 'express' )
Promise = require( 'bluebird' )
rest = require( 'restler' )
Sequelize = require( 'sequelize' )

class Sandglass
  constructor: ( options ) ->
    @defaults =
      headless: false

      server:
        port: 3000

      api:
        base: '/api/0.1'

      frontend:
        host: 'http://localhost:3000/api/0.1'
        cookie:
          name: 'auth'
          options:
            expires: new Date( Date.now() + 1000 * 60 * 60 * 24 )
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

    # auth middleware
    @app.sessionAuth = ( req, res, next ) =>
      failed = false

      if not req.cookies?
        failed = true
      else
        session = req.cookies[ @app.options.frontend.cookie.name ]

      if not session
        failed = true

      if failed
        return res.status( 403 ).end()

      rest.get( @app.options.frontend.host + '/sessions/' + session )
        .on 'complete', ( jres, err ) ->

          if not jres or not jres.users
            return res.status( 403 ).end()

          req.user = jres.users[ 0 ]
          next()

    @mount( require( './routes/index' )( @app ) )

  setupAPI: ->
    @app.API_VERSION = '0.1'

    # initialize response object
    @app.use ( req, res, next ) ->
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

    @mount( require( './routes/api/index' )( @app ) )

    # execute response
    @app.all '/api/*', ( req, res, next ) ->
      if res.data
        if( res.data.length is 1 )
          res.json( res.data[ 0 ] )
        else
          res.json( res.data )

  setupModels: ->
    models = require( './models/index' )( @app.db )

    for index, model of models
      if( model.associate? )
        model.associate( models )

    @app.models = @models = models

  setupFixtures: ->
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

      @models.Role
        .post( role )
        .then ( role ) =>
          @models.User.post( user )
        .then( resolve, reject )

  mount: ( routes ) ->
    for router in routes
      @app.use router

  start: () ->
    @setupDatabase()
    @setupModels()

    @app.use( bodyParser.urlencoded( { extended: true } ) )
    @app.use( bodyParser.json() )
    @app.use( cookieParser() )

    @setupAPI()

    if not @options.headless
      @setupViews()

    @app.db.sync()
      .then =>
        @setupFixtures()
      .then =>
        @app.listen @options.server.port

module.exports = Sandglass