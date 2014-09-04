crud = require( '../utils/crud.coffee' )
errors = require( '../errors/index.coffee' )
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
        new Promise ( resolve, reject ) =>
          title = req.body.title

          find =
            where:
              title: title
            defaults:
              title: title

          if context? and context.user?
            context_user = context.user
            find.where.UserId = context_user.id

          if context? and context.activity?
            context_activity = context.activity

          @.findOrCreate( find )
            # set user
            .spread ( task, created ) ->
              if not context_user
                return task

              task.setUser( context_user )

            # set activity
            .then ( task ) ->
              if not context_activity
                return task

              new Promise ( resolve, reject ) ->
                context_activity.setTask( task )
                  .then( resolve( task ), reject )

            .then ( task ) ->
              resolve( tasks: [ task ] )
            .catch( reject )

      get: ( req, context, id ) ->
        find =
          where: {}

        if id?
          find.where.id = id

        if context? and context.user?
          find.where.UserId = context.user.id

        crud.READ.call( @, find, id )
    }

  )
