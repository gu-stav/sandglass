errors = require( '../errors/index.coffee' )
Promise = require( 'bluebird' )

module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'Tag',

    title:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    {
    classMethods:
      associate: ( models )->
        @.belongsTo( models.User )
        @.hasMany( models.Activity )

        @.__models =
          User:models.User

      post: ( req, user ) ->
        new Promise ( resolve, reject ) =>
          title = req.body.title

          if not title
            return resolve()

          where =
            where:
              title: req.body.title

          create =
            title: title

          if user?
            where.where.UserId = user.id

          @.find( where )
            .then ( tag ) =>
              if tag
                return resolve( tag )

              @.create( create )
                .then( tag ) ->
                  if not user?
                    return resolve( tag )

                  @.__models.User.get( req, user.id, single: true )
                    .then ( user ) ->
                      tag.setUser( user )
                        .then( resolve, reject )

      get: ( req, user, id ) ->
        return new Promise ( resolve, reject ) =>
          find =
            where: {}

          if user?
            find.where.UserId = user.id

          if id?
            find.where.id = id

          @.findAll( where )
            .then ( tags ) ->
              if id? and not tags.length
                return reject( errors.NotFound( 'Tag' ) )

              resolve( tags: tags )
    }

  )
