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

      post: ( req, context ) ->
        return new Promise ( resolve, reject ) =>
          title = req.body.title

          if context? and context.user?
            context_user = context.user

          if context? and context.activity?
            context_activity = context.activity

          create =
            title: title

          find =
            where:
              title: title

          if context_user
            find.where.UserId = context_user.id

          if context_activity
            find.where.ActivityId = context_activity.id

          @.findOrCreate( find, create )
            # set user
            .then ( task ) ->
              if context_user?
                task.setUser( context_user )
              else
                task
            # set activity
            .then ( task ) ->
              if context_activity?
                task.setActivity( context_activity )
              else
                task
            .then( resolve, reject )

      get: ( req, context, id ) ->
        return new Promise ( resolve, reject ) =>
          find =
            where: {}

          if id?
            find.where.id = id

          if context? and context.user?
            find.where.UserId = context.user.id

          if context? and context.activity?
            find.where.ActivityId = context.activity.id

          @.findAll( find )
            .then ( tasks ) ->
              resolve( tasks: tasks )
            .catch( reject )
    }

  )
