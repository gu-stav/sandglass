Promise = require( 'bluebird' )

module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'Project',

    title:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    {
    classMethods:
      associate: ( models )->
        @.belongsTo( models.User )
        @.hasMany( models.Task )
        @.hasOne( models.Activity )

        @.__models =
          User:models.User

      post: ( req, user ) ->
        return new Promise ( resolve, reject ) =>
          title = req.body.title

          if not title
            return resolve()

          create =
            title: title

          where =
            where:
              title: req.body.title

          if user?
            where.where.UserId = user.id

          @.find( where )
            .then ( project ) =>
              if not project
                @.create( create )
                  .then ( project ) =>
                    if not user?
                      return resolve( project )

                    @.__models.User.get( req, user.id )
                      .then ( user ) ->
                        project.setUser( user )
                          .then( resolve, reject )
                  .then( resolve, reject )
              else
                resolve( project )

      get: ( req, user, id ) ->
        return new Promise ( resolve, reject ) =>
          where =
            where: {}

          if user?
            where.where.UserId = user.id

          if id?
            where.where.id = id

          @.findAll( where )
            .then ( projects ) ->
              resolve( projects: projects )
    }

  )
