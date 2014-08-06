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

      findBySession: ( session ) ->
        new Promise ( resolve, reject ) =>
          search =
            where:
              session: session

          this.find( search )
            .then( resolve, reject )

      signup: ( data ) ->
        new Promise ( resolve, reject ) =>
          rawPassword = data._rawPassword

          if not rawPassword
            throw new Error( '_rawPassword was not provided.' )

          bcrypt.genSalt 12, ( err, salt ) =>
            if err
              throw new Error( err )

            bcrypt.hash rawPassword, salt, ( err, hash ) =>
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
                .then( resolve, reject )

      logout: ( session ) ->
        new Promise ( resolve, reject ) =>
          @.findBySession( session )
            .then ( user ) ->
              if not user
                throw new Error( 'User not found' )

              update =
                session: ''

              user.updateAttributes( update )
                .then( resolve, reject )

      login: ( data ) ->
        new Promise ( resolve, reject ) =>
          password = data.password
          email = data.email

          if not password
            throw new Error( 'No password was provided' )

          if not email
            throw new Error( 'No email was provided' )

          search =
            where:
              email: email

          @.find( search )
            .then ( user ) =>
              if not user
                throw new Error( 'User was not found' )

              if user.session
                # user is already logged in, so we don't need to create
                # a new session string
                return resolve( user )

              bcrypt.compare password, user.password, ( err, res ) =>
                if err
                  throw new Error( err )

                if not res
                  throw new Error( 'Passwords do not match' )

                # create new session
                session = crypto.createHash( 'sha1' )
                            .update( crypto.randomBytes( 20 ) )
                            .digest( 'hex' )

                update =
                  session: session

                user.updateAttributes( update )
                  .then( resolve, reject )

    instanceMethods:
      render: ( password = false, salt = false ) ->
        omit = []

        if not password
          omit.push( 'password' )

        if not salt
          omit.push( 'salt' )

        return user: _.omit( @.toJSON(), omit )
    }

  )
