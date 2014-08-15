_ = require( 'lodash' )
bcrypt = require( 'bcrypt' )
crypto = require( 'crypto' )
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
      associate: ( models )->
        @.__models =
          Role: models.Role

        @.belongsTo( models.Role )
        @.hasOne( models.Activity )
        @.hasOne( models.Project )
        @.hasOne( models.Task )

      findBySession: ( session, options ) ->
        options = _.defaults( options || {}, full: false )

        new Promise ( resolve, reject ) =>
          search =
            where:
              session: session

          this.find( search )
            .then ( user ) ->
              if not user
                reject( new Error( 'User not found' ) )
              else
                if not options.full
                  resolve( users: [ user.render() ] )
                else
                  resolve( users: [ user ] )

      auth: ( req ) ->
        return new Promise ( resolve, reject ) =>
          session = req.cookies.auth

          if not session
            reject( new Error( 'No session was provided' ) )

          @.findBySession( session, { full: true } )
            .then ( users ) ->
              if not users or not users.users.length
                resolve( false )
              else
                resolve( users )

      post: ( req ) ->
        data = req.body

        new Promise ( resolve, reject ) =>
          if not data._rawPassword
            throw new Error( '_rawPassword was not provided.' )

          bcrypt.genSalt 12, ( err, salt ) =>
            if err
              throw new Error( err )

            bcrypt.hash data._rawPassword, salt, ( err, hash ) =>
              if err
                throw new Error( err )

              data.password = hash

              @.create( data )
                .then ( user ) =>
                  if not user
                    throw new Error( 'No user created' )

                  new Promise ( resolve, reject ) =>
                    @.__models.Role.getDefault()
                      .then ( role ) =>
                        user.setRole( role )
                          .then( resolve, reject )
                .then ( user ) ->
                  resolve( users: [ user.render() ] )

      get: ( req, id ) ->
        new Promise ( resolve, reject ) =>
          if id
            @.find( id )
            .then ( user ) ->
              if not user
                reject( new Error( 'User not found' ) )

              resolve( users: [ user.render() ] )
          else
            @.findAll()
              .then ( users ) =>
                result = []
                for index, user of users
                  result.push( user.render() )

                resolve( users: result )

      logout: ( req ) ->
        new Promise ( resolve, reject ) =>
          session = req.cookies.auth;

          @.findBySession( session )
            .then ( user ) ->
              update =
                session: null

              user.updateAttributes( update )
                .then ( user ) ->
                  resolve( users: [ user ] )
                .catch( reject )
            .catch( reject )

      login: ( req ) ->
        new Promise ( resolve, reject ) =>
          password = req.body.password
          email = req.body.email

          if not password
            reject( new Error( 'No password was provided' ) )

          if not email
            reject( new Error( 'No email was provided' ) )

          search =
            where:
              email: email

          @.find( search )
            .then ( user ) =>
              if not user
                reject( new Error( 'User was not found' ) )

              if user.session
                # user is already logged in, so we don't need to create
                # a new session string
                return resolve( users: [ user.render() ] )

              bcrypt.compare password, user.password, ( err, res ) =>
                if err
                  reject( new Error( err ) )

                if not res
                  reject( new Error( 'Passwords do not match' ) )

                # create new session
                session = crypto.createHash( 'sha1' )
                            .update( crypto.randomBytes( 20 ) )
                            .digest( 'hex' )

                update =
                  session: session

                user.updateAttributes( update )
                  .then ( user ) ->
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
