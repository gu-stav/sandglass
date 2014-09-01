Promise = require( 'bluebird' )

module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'Task',

    title:
      type: DataTypes.STRING
      allowNull: false

    {
    classMethods:
      associate: ( models )->
        @.belongsTo( models.User )
        @.hasMany( models.Project )
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
              title: title

          if user?
            where.where.UserId = user.id

          @.find( where )
            .then ( task ) =>
              if task
                resolve( task )
              else
                @.create( create )
                  .then ( task ) =>
                    if not user?
                      return resolve( task )

                    @.__models.User.get( req, user.id, single: true )
                      .then ( user ) ->
                        task.setUser( user )
                          .then( resolve, reject )
                  .then( resolve, reject )

      get: ( req, user, id ) ->
        return new Promise ( resolve, reject ) =>
          where =
            where: {}

          if user?
            where.where.UserId = user.id

          if id?
            where.where.id = id

          @.findAll( where )
            .then ( tasks ) ->
              resolve( tasks: tasks )
            .catch( reject )
    }

  )
