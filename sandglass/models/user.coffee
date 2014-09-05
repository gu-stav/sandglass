_ = require( 'lodash' )
bcrypt = require( 'bcrypt' )
crud = require( '../utils/crud.coffee' )
crypto = require( 'crypto' )
errors = require( '../errors/index.coffee' )
Promise = require( 'bluebird' )

module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'User',

    name:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true

    email:
      type: DataTypes.STRING
      allowNull: false
      unique: true
      validate:
        isEmail: true

    password:
      type: DataTypes.STRING
      allowNull: false
      validate:
        notEmpty: true

    salt:
      DataTypes.STRING

    session:
      DataTypes.STRING

    {
    classMethods:
      associate: ( models, app )->
        @.__models =
          Role: models.Role

        @.__app = app

        @.belongsTo( models.Role )
        @.hasOne( models.Activity )
        @.hasOne( models.Project )
        @.hasOne( models.Task )
        @.hasOne( models.Tag )

      actionSupported: ( action, method ) ->
        mapping =
          session: [ 'get' ]
          login:   [ 'post' ]
          logout:  [ 'get' ]

        if mapping[ action ]
          mapping[ action ].indexOf( method ) isnt -1
        else
          action is method

      session: ( req, context, id, res ) ->
        session = req.getSessionCookie()

        if not session
          return Promise.reject( new errors.BadRequest( 'No session cookie submitted' ) )

        find =
            where:
              session: session

        crud.READ.call( @, find, true )

      post: ( req, context ) ->
        data = req.body

        new Promise ( resolve, reject ) =>
          if not data._rawPassword
            return reject( errors.BadRequest( '_rawPassword not submitted' ) )

          bcrypt.genSalt 12, ( err, salt ) =>
            if err
              return reject ( err )

            bcrypt.hash data._rawPassword, salt, ( err, hash ) =>
              if err
                return reject( err )

              data.password = hash

              crud.CREATE.call( @, data )
                .catch( reject )
                .then ( user ) =>
                  @.__models.Role.getDefault()
                    .then ( role ) ->
                      user.setRole( role )
                .then ( user ) ->
                  resolve( users: [ user.render() ] )
                .catch( reject )

      get: ( req, context, id ) ->
        find =
          where: {}

        if id?
          find.where.id = id

        crud.READ.call( @, find, id )

      logout: ( req, context, id, response ) ->
        new Promise ( resolve, reject ) =>
          session = req.getSessionCookie();

          response.clearCookie( @.__app.options.cookie.name )

          @.findBySession( session )
            .then ( user ) ->
              user.updateAttributes( session: null )
            .then ( user ) ->
              resolve( user )
            .catch( reject )

      login: ( req, context, response ) ->
        new Promise ( resolve, reject ) =>
          data = req.body
          password = data.password
          email = data.email

          if not email
            return reject( new errors.BadRequest( 'Invalid Email', 'email' ) )

          if not password
            return reject( new errors.BadRequest( 'Invalid password', 'password' ) )

          find =
            where:
              email: email

          crud.READ.call( @, find, true )
            .catch( reject )
            .then ( user ) =>
              if user.session = req.sandglass.user.session
                return resolve( user )

              bcrypt.compare password, user.password, ( err, res ) =>
                if err
                  return reject( err )

                if not res
                  return reject( new errors.BadRequest( 'Invalid login credentials' ) )

                # create new session
                session = crypto.createHash( 'sha1' )
                            .update( crypto.randomBytes( 20 ) )
                            .digest( 'hex' )

                update =
                  session: session

                user.updateAttributes( update )
                  .then () =>
                    # set response cookie
                    cookieName = @.__app.options.cookie.name
                    cookieOptions = @.__app.options.cookie.options
                    session = user.session
                    req.sandglass.data.cookie = [ cookieName, session, cookieOptions ]

                    resolve( user )

    instanceMethods:
      render: ( password = false, salt = false ) ->
        omit = []

        if not password
          omit.push( 'password' )

        if not salt
          omit.push( 'salt' )

        return _.omit( @.dataValues, omit )
    }

  )
