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

      post: ( req, context ) ->
        return new Promise ( resolve, reject ) =>
          title = req.body.title

          create =
            title: title

          find =
            where:
              title: req.body.title

          if context? and context.user?
            context_user = context.user
            find.where.UserId = context.user.id

          if context? and context.activity?
            context_activity = context.activity

          @.findOrCreate( find, create )
            .then ( project ) ->
              if context_user
                project.setUser( context_user )
              else
                project
            .then ( project ) ->
              if context_activity
                project.setActivity( context_activity )
              else
                project
            .then( resolve, reject )

      get: ( req, context, id ) ->
        return new Promise ( resolve, reject ) =>
          find =
            where: {}

          if context? and context.user?
            find.where.UserId = context.user.id

          if context? and context.activity?
            find.where.ActivityId = context.activity.id

          if id?
            find.where.id = id

          @.findAll( find )
            .then ( projects ) ->
              resolve( projects: projects )
    }

  )
