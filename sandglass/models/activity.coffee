errors = require( '../errors/index.coffee' )
date = require( '../utils/date.coffee' )
moment = require( 'moment' )
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
          Tag: models.Tag
          User: models.User

        @.belongsTo( models.User )
        @.belongsTo( models.Project )
        @.belongsTo( models.Task )

        @.hasMany( models.Tag )

      post: ( req, context ) ->
        new Promise ( resolve, reject ) =>
          start = req.body.start or new Date()
          end = req.body.end or undefined
          description = req.body.description or ''

          if context? and context.user?
            context_user = context.user

          create =
            start: start
            end: end
            description: description

          @.create( create )
            .catch( reject )
            .then ( activity ) =>
              if context_user
                activity.setUser( context_user )
              else
                return activity
            .then ( activity ) ->
              resolve( activities: [ activity ] )

      get: ( req, context, id ) ->
        includes = [ @.__models.Task,
                     @.__models.Project,
                     @.__models.Tag ]

        new Promise ( resolve, reject ) =>
          from = req.param( 'from' )
          to = req.param( 'to' )
          find =
            where: {}
            include: includes
            order: [
              [ 'start', 'ASC' ]
            ]

          if id?
            find.where.id = id

          if context? and context.user?
            context_user = context.user
            find.where.UserId = context_user.id

          if from
            from = date.fromString( from ).toDate()

          if to
            to = date.fromString( to ).toDate()

          if from? and to?
            find.where.start = between: [ from, to ]
          else
            if from?
              find.where.start = gt: from

            if to?
              find.where.start = lt: to

          @.findAll( find )
            .then ( activities ) ->
              if not activities and not activities.length
                reject( errors.NotFound( 'Activity' ) )

              resolve( activities: activities )

      update: ( req, context, id ) ->
        new Promise ( resolve, reject ) =>
          data = req.body
          find =
            where:
              id: id

          if context? and context.user?
            find.where.UserId = context.user.id

          @.find( find )
            .then ( activity ) ->
              if not activity
                return reject( errors.NotFound( 'Activity' ) )

              activity.updateAttributes( data )
                .then ( activity ) ->
                  resolve( activities: [ activity ] )
                .catch( reject )

      delete: ( req, context, id ) ->
        new Promise ( resolve, reject ) =>
          find =
            where:
              id: id

          if context? and context.user?
            find.where.UserId = context.user.id

          @.find( find )
            .then ( activity ) ->
              if not activity
                return reject( errors.NotFound( 'Activity not found' ) )

              activity.destroy()
                .then ( activity ) ->
                  resolve( activities: [ activity ] )
                .catch( reject )
    }

  )
