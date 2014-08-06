Promise = require( 'bluebird' )

module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'Activity',

    start:
      type: DataTypes.DATE
      allowNull: false

    end:
      type: DataTypes.DATE
      allowNull: true

    description:
      type: DataTypes.TEXT
      allowNull: true

    title:
      type: DataTypes.STRING
      allowNull: false

    {
    classMethods:
      associate: ( models )->
        @.belongsTo( models.User )

      post: ( req ) ->
        return new Promise ( resolve, reject ) =>
          start = req.body.start or new Date()
          end = req.body.end or undefined
          description = req.body.description or ''
          title = req.body.title

          create =
            start: start
            end: end
            description: description
            title: title

          @.create( create )
            .then ( activity ) =>
              if not activity
                throw new Error( 'Can not create activity' )

              activity.setUser( req.user )
            .then( resolve, reject )

      get: ( req, id ) ->
        where =
          userId: req.user.id

        if id?
          where.id = id

        @.findAll( where )
    }

  )
