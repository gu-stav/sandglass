crud = require( '../utils/crud' )
errors = require( '../errors/index' )
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

        crud.CREATE.call( @, find )

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
