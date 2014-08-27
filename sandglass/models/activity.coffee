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
        new Promise ( resolve, reject ) =>
          start = req.body.start or new Date()
          end = req.body.end or undefined
          description = req.body.description or ''
          ACTIVITY = undefined

          create =
            start: start
            end: end
            description: description

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
        new Promise ( resolve, reject ) =>
          user = req.user
          from = req.param( 'from' )
          to = req.param( 'to' )

          search =
            where:
              userId: user.id,
            include: [ @.__models.Task,
                       @.__models.Project ]
            order: [
              [ 'start', 'ASC' ]
            ]

          if id?
            search.where.id = id

          if from? and to?
            search.where.start = between: [ from, to ]
          else
            if from?
              search.where.start = gt: from

            if to?
              search.where.start = lt: to

          @.findAll( search )
            .then ( activities ) ->
              resolve( activities: activities )
            .catch( reject )

      update: ( req, id ) ->
        new Promise ( resolve, reject ) =>
          data = req.body

          @.find( id )
            .then ( activity ) ->
              if not activity
                return reject( new Error( 'Activity not found' ) )

              activity.updateAttributes( data )
                .then ( activity ) ->
                  resolve( activities: [ activity ] )
                .catch( reject )
    }

  )
