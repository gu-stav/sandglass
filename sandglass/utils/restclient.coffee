Promise = require( 'bluebird' )
rest = require( 'restler' )

createSuccess = ( data ) ->
  data

createFail = ( data ) ->
  data

createData = ( req ) ->
  data =
    data: req.body
    headers: req.headers

rest_init = ( app ) ->
  this.baseUrl = app.options.host

rest_defaults = {}

rest_urls =
  _user_resource: ( resource, req, res, get ) ->
    userId = res.getUser().id

    new Promise ( resolve, reject ) =>
      this.get( "#{this.baseUrl}/users/#{userId}/#{resource}#{get}", createData( req ) )
        .on 'complete', ( result_data ) ->
          resolve( createSuccess( result_data ) )
        .on 'fail', ( result_data, result_response ) ->
          reject( createFail( result_data, result_response ) )

  user_activities_get: ( req, res, get ) ->
    this._user_resource( 'activities', req, res, get )

  user_tasks_get: ( req, res, get ) ->
    this._user_resource( 'tasks', req, res, get )

  user_projects_get: ( req, res, get ) ->
    this._user_resource( 'projects', req, res, get )

module.exports = rest.service( rest_init, rest_defaults, rest_urls )
