date = require( '../utils/date.coffee' )
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

          create =
            start: start
            end: end
            description: description

          @.create( create )
            .then ( activity ) =>
              activity.setUser( req.user )
                .then( resolve, reject )
            .catch( reject )

      get: ( req, id ) ->
        new Promise ( resolve, reject ) =>
          user = req.user
          from = date.fromString( req.param( 'from' ) )
          to = date.fromString( req.param( 'to' ) )

          if from
            from = from.toDate()

          if to
            to = to.toDate()

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

      delete: ( req, id ) ->
        new Promise ( resolve, reject ) =>
          @.find( id )
            .then ( activity ) ->
              if not activity
                return reject( new Error( 'Activity not found' ) )

              activity.destroy()
                .then ( activity ) ->
                  resolve( activities: [ activity ] )
                .catch( reject )

    instanceMethods:
      addInstance: ( model, req ) ->
        new Promise ( resolve, reject ) =>
          model.post( req )
            .then ( inst ) =>
              if not inst
                resolve( @ )

              @[ 'set' + model.name ]( inst )
                .then( resolve, reject )

    }

  )
