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
          title = req.body.title

          if not title
            return resolve()

          create =
            title: title

          where =
            where:
              title: title
              UserId: req.user.id

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
        return new Promise ( resolve, reject ) =>
          where =
            where:
              UserId: req.user.id

          if id?
            where.where.id = id

          @.findAll( where )
            .then ( tasks ) ->
              resolve( tasks: tasks )
    }

  )
