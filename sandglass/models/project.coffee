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
          title = req.body.title

          if not title
            return resolve()

          create =
            title: title

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
        return new Promise ( resolve, reject ) =>
          where =
            where:
              UserId: req.user.id

          if id?
            where.where.id = id

          @.findAll( where )
            .then ( projects ) ->
              resolve( projects: projects )
    }

  )
