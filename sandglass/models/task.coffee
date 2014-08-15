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

      post: ( req ) ->
        return new Promise ( resolve, reject ) =>
          create =
            title: req.body.title

          where =
            where:
              title: req.body.title
              userId: req.user.id

          @.find( where )
            .then ( task ) =>
              if task
                resolve( task )
              else
                @.create( create )
                  .then ( task ) =>
                    task.setUser( req.user )
                  .then( resolve, reject )


      get: ( req, id ) ->
        where =
          userId: req.user.id

        if id?
          where.id = id

        @.findAll( where )
    }

  )
