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

      post: ( req ) ->
        return new Promise ( resolve, reject ) =>
          create =
            title: req.body.title

          where =
            where:
              title: req.body.title
              userId: req.user.id

          @.find( where )
            .then ( project ) =>
              if not project
                @.create( create )
                  .then ( project ) =>
                    project.setUser( req.user )
                  .then( resolve, reject )
              else
                resolve( project )

      get: ( req, id ) ->
        where =
          userId: req.user.id

        if id?
          where.id = id

        @.findAll( where )
    }

  )
