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
          search =
            where:
              session: session

          this.find( search )
            .then ( user ) ->
              if not user
                return reject( new Error( 'User not found' ) )

              if not options.full
                user = user.render()

              resolve( users: [ user ] )

      auth: ( req ) ->
        return new Promise ( resolve, reject ) =>
          session = req.getSessionCookie()

          if not session
            reject( errors.NoPermission( 'No session provided' ) )

          @.findBySession( session, { full: true } )
            .then ( user ) ->
              resolve( user )

      post: ( req ) ->
        data = req.body

        new Promise ( resolve, reject ) =>
          if not data._rawPassword
            return reject( new Error( '_rawPassword was not provided.' ) )

          bcrypt.genSalt 12, ( err, salt ) =>
            if err
              return reject ( err )

            bcrypt.hash data._rawPassword, salt, ( err, hash ) =>
              if err
                return reject( err )

              data.password = hash

              @.create( data )
                .then ( user ) =>
                  if not user
                    return reject( new Error( 'No user created' ) )

                  new Promise ( resolve, reject ) =>
                    @.__models.Role.getDefault()
                      .then ( role ) =>
                        user.setRole( role )
                          .then( resolve, reject )
                .then ( user ) ->
                  resolve( users: [ user.render() ] )

      get: ( req, id, options ) ->
        includes = [ @.__models.Role ]

        new Promise ( resolve, reject ) =>

          # fast path - user was already preloaded
          if req.user and req.user.id is id
            return resolve( req.user )

          where =
            where:
              id: id
            include: includes

          if id
            @.find( where )
            .then ( user ) ->
              if not user
                return reject( errors.BadRequest( 'User not found' ) )

              if options? and options.single?
                return resolve( user.render() )

              resolve( users: [ user.render() ] )
          else
            where =
              include: includes

            @.findAll( where )
              .then ( users ) ->
                result = []

                for index, user of users
                  result.push( user.render() )

                return result
              .then ( users ) ->
                resolve( users: result )

      logout: ( req, response ) ->
        new Promise ( resolve, reject ) =>
          session = req.getSessionCookie();

          response.clearCookie( @.__app.options.cookie.name )

          @.findBySession( session )
            .then ( user ) =>
              update =
                session: null

              user.updateAttributes( update )
                .then ( user ) =>
                  resolve( users: [ user ] )
                .catch( reject )
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
                return reject( new Error( 'Invalid login credentials' ) )

              if not password
                return reject( new Error( 'No password provided' ) )

              bcrypt.compare password, user.password, ( err, res ) =>
                if err
                  return reject( err )

                if not res
                  return reject( new Error( 'Invalid password' ) )

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
