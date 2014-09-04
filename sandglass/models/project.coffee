crud = require( '../utils/crud.coffee' )
errors = require( '../errors/index.coffee' )
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
        new Promise ( resolve, reject ) =>
          title = req.body.title

          find =
            where:
              title: req.body.title
            defaults:
              title: title

          if context? and context.user?
            context_user = context.user
            find.where.UserId = context.user.id

          if context? and context.activity?
            context_activity = context.activity

          @.findOrCreate( find )
            # set user
            .spread ( project, created ) ->
              if not context_user
                return project

              project.setUser( context_user )

            # set activity
            .then ( project ) ->
              if not context_activity
                return project

              new Promise ( resolve, reject ) ->
                context_activity.setProject( project )
                  .then( resolve( project ), reject )

            .then ( project ) ->
              resolve( projects: [ project ] )

      get: ( req, context, id ) ->
        find =
          where: {}

        if context? and context.user?
          find.where.UserId = context.user.id

        if context? and context.activity?
          find.where.ActivityId = context.activity.id

        if id?
          find.where.id = id

        crud.READ.call( @, find, id )
    }

  )
