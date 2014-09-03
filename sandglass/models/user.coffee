_ = require( 'lodash' )
bcrypt = require( 'bcrypt' )
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

      findBySession: ( session, options ) ->
        options = _.defaults( options || {}, full: false )

        new Promise ( resolve, reject ) =>
          find =
            where:
              session: session

          this.find( find )
            .then ( user ) ->
              if not user
                return reject( errors.NotFound( 'User' ) )

              if not options.full
                user = user.render()
                resolve( users: [ user ] )
              else
                resolve( user )

      auth: ( req ) ->
        return new Promise ( resolve, reject ) =>
          session = req.getSessionCookie()

          if not session
            reject( errors.NoPermission( 'Session Cookie missing' ) )

          @.findBySession( session, { full: true } )
            .then( resolve, reject )

      post: ( req ) ->
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

              @.create( data )
                .catch( reject )
                .then ( user ) =>
                  @.__models.Role.getDefault()
                    .then ( role ) ->
                      user.setRole( role )
                .then ( user ) ->
                  resolve( users: [ user.render() ] )
                .catch( reject )

      get: ( req, id, options ) ->
        includes = [ @.__models.Role ]

        new Promise ( resolve, reject ) =>
          # fast path - user was already preloaded
          if req.user and req.user.id is id
            if options? and options.single?
              return resolve( req.user )

            resolve( users: req.user.render() )

          find =
            where: {}
            include: includes

          if id?
            find.where.id = id

          @.findAll( find )
            .then ( users ) ->
              # a single user was requested, but not found
              if id? and not users.length
                return reject( errors.NotFound( 'User' ) )

              # return a single raw DAO
              if users.length is 1 and ( options? and options.single? )
                return resolve( users[ 0 ] )

              resolve( users: ( user.render() for user in users ) )

      logout: ( req, response ) ->
        new Promise ( resolve, reject ) =>
          session = req.getSessionCookie();

          response.clearCookie( @.__app.options.cookie.name )

          @.findBySession( session )
            .then ( user ) ->
              user.updateAttributes( session: null )
            .then ( user ) ->
              resolve( users: [ user ] )
            .catch( reject )

      login: ( req, response ) ->
        new Promise ( resolve, reject ) =>
          data = req.body
          password = data.password
          email = data.email

          if not email
            return reject( errors.BadRequest( 'Invalid Email', 'email' ) )

          if not password
            return reject( errors.BadRequest( 'Invalid password', 'password' ) )

          search =
            where:
              email: email

          @.find( search )
            .then ( user ) =>
              if not user
                return reject( errors.BadRequest( 'Invalid login credentials' ) )

              bcrypt.compare password, user.password, ( err, res ) =>
                if err
                  return reject( err )

                if not res
                  return reject( errors.BadRequest( 'Invalid login credentials' ) )

                # create new session
                session = crypto.createHash( 'sha1' )
                            .update( crypto.randomBytes( 20 ) )
                            .digest( 'hex' )

                update =
                  session: session

                user.updateAttributes( update )
                  .then ( user ) =>
                    # set response cookie
                    cookieName = @.__app.options.cookie.name
                    cookieOptions = @.__app.options.cookie.options
                    session = user.session
                    response.cookie( cookieName, session, cookieOptions )

                    resolve( users: [ user.render() ] )

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
