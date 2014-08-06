module.exports = ( sequelize, DataTypes ) ->
  sequelize.define(
    'Role',

    name:
      type: DataTypes.STRING
      allowNull: false
      unique: true

    default:
      type: DataTypes.BOOLEAN
      allowNull: true
      defaultValue: false

    admin:
      type: DataTypes.BOOLEAN
      allowNull: true
      defaultValue: false

    {
    classMethods:
      associate: ( models )->
        @.hasMany( models.User )

      post: ( req ) ->
        @.create( req.body )

      getDefault: ->
        where =
          default: true

        @.find( where )
    }

  )
