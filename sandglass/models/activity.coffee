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
        @.__models =
          Task: models.Task
          Project: models.Project

        @.belongsTo( models.User )
        @.belongsTo( models.Project )
        @.belongsTo( models.Task )

      post: ( req ) ->
        return new Promise ( resolve, reject ) =>
          start = req.body.start or new Date()
          end = req.body.end or undefined
          description = req.body.description or ''
          title = req.body.title
          ACTIVITY = undefined

          create =
            start: start
            end: end
            description: description
            title: title

          @.create( create )
            .then ( activity ) =>
              if not activity
                reject( new Error( 'Can not create activity' ) )

              ACTIVITY = activity
              activity.setUser( req.user )
            .then ( activity ) =>
              post =
                body:
                  title: req.body.task
                user: req.user

              @.__models.Task.post( post )

            .then ( task ) =>
              ACTIVITY.setTask( task )

            .then ( activity ) =>
              post =
                body:
                  title: req.body.project
                user: req.user

              @.__models.Project.post( post )

            .then ( project ) =>
              ACTIVITY.setProject( project )

            .then( resolve, reject )

      get: ( req, id ) ->
        return new Promise ( resolve, reject ) =>
          user = req.user

          search =
            where:
              userId: user.id
            include: [ @.__models.Task, @.__models.Project ]

          if id?
            search.where.id = id

          @.findAll( search )
            .then ( activities ) ->
              resolve( activities: activities )
    }

  )
