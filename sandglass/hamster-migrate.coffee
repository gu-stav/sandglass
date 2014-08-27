Promise = require( 'bluebird' )
rest = require( 'restler' )
sqlite = require( 'sqlite3' )

frontend_conf = require( '../config-frontend.json' )

module.exports = ( username, password, file ) ->
  new Promise ( resolve, reject ) ->
    db = new sqlite.Database( file )

    login_url = frontend_conf.host + '/login'

    userData =
      data:
        email: username
        password: password

    rest.post( login_url, userData )
      .on 'success', ( jres, rres ) ->
        session = jres.users[ 0 ].session
        userId = jres.users[ 0 ].id

        activity_url = frontend_conf.host + '/users/' + userId + '/activities'

        db.each 'SELECT * FROM fact_index', ( err, fact ) ->
          task = fact.name
          project = fact.category
          description = fact.description
          tag = fact.tag

          data =
            data:
              task: task
              project: project
              description: description
            headers:
              'Cookie': 'auth=' + session

          rest.post( activity_url, data )

        db.close()
        resolve()