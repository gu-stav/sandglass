crud = require( '../utils/crud' )
errors = require( '../errors/index' )
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
        @.hasMany( models.Project )

      post: ( req, context, res ) ->
        title = req.body.title

        find =
          where:
            title: title
          defaults:
            title: title

        if context? and context.user?
          find.where.UserId = context.user.id
          find.defaults.UserId = context.user.id

        if context? and context.activity?
          context_activity = context.activity

        crud.CREATE.call( @, find )
          # set activity
          .then ( task ) ->
            if not context_activity
              return Promise.resolve( task )

            context_activity.setTask( task )
              .then( Promise.resolve( task ) )
              .catch( Promise.reject )

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
