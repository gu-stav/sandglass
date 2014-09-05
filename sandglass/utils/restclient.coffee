Promise = require( 'bluebird' )
rest = require( 'restler' )
url = require( 'url' )

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
  _user_resource_get: ( resource, req, res, get, method ) ->
    user = res.getUser()

    if not method?
      method = 'get'

    if user
      userId = user.id
    else
      userId = ''

    if not resource
      resource = ''

    request_url = "#{this.baseUrl}/users/#{userId}"

    if resource
      request_url += "/#{resource}"

    if get
      if typeof get is 'object'
        get = url.format( query: get )

      request_url += "#{get}"

    request_data = createData( req )

    new Promise ( resolve, reject ) =>
      @[method]( request_url, request_data )
        .on 'complete', ( result_data, raw_response ) ->
          res.set( raw_response.headers )
          res.set({
            'Content-Type': 'text/html; charset=utf-8'
            })
          resolve( result_data, raw_response )
        .on 'fail', ( result_data, raw_response ) ->
          reject( createFail( result_data, raw_response ) )

  user_activities_get: ( req, res, get ) ->
    @._user_resource_get( 'activities', req, res, get )

  user_tasks_get: ( req, res, get ) ->
    @._user_resource_get( 'tasks', req, res, get )

  user_projects_get: ( req, res, get ) ->
    @._user_resource_get( 'projects', req, res, get )

  user_login_post: ( req, res, get ) ->
    @._user_resource_get( null, req, res, get, 'post' )

  user_logout_get: ( req, res, get ) ->
    @._user_resource_get( null, req, res, get )

  auth_get: ( req, res, get ) ->
    @._user_resource_get( null, req, res, get )

  activity_post: ( req, res, get ) ->
    @._user_resource_get( 'activities', req, res, get, 'post' )

  activity_task_post: ( id, req, res, get ) ->
    @._user_resource_get( 'activities/' + id + '/tasks', req, res, get, 'post' )

  activity_project_post: ( id, req, res, get ) ->
    @._user_resource_get( 'activities/' + id + '/projects', req, res, get, 'post' )

module.exports = rest.service( rest_init, rest_defaults, rest_urls )
