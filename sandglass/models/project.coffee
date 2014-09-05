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

      post: ( req, context, res ) ->
        title = req.body.title

        find =
          where:
            title: req.body.title
          defaults:
            title: title

        if context? and context.user?
          find.where.UserId = context.user.id
          find.defaults.UserId = context.user.id

        if context? and context.activity?
          context_activity = context.activity

        crud.CREATE.call( @, find )
          # set activity
          .then ( project ) ->
            if not context_activity
              return Promise.resolve( project )

            context_activity.setProject( project )
              .then( Promise.resolve( project ) )
              .catch( Promise.reject )

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
