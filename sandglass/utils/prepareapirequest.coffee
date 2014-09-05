prepare_request = ( req, res, next ) ->
  req.sandglass =
    context: {}
    user: {}
    data: {}

  # return value of the session-cookie
  req.getSessionCookie = () =>
    if req.sandglass.user and req.sandglass.user.session
      req.sandglass.user.session
    else
      req.cookies[ req.getSessionCookieName() ] or undefined

  req.getSessionCookieName = () =>
    return 'auth'

  req.getSessionCookieOptions = () =>
    options =
      expires: 8640000
      httpOnly: true

    options.expires = new Date( Date.now() + options.expires )

    return options

  # save a cookie which will be sent through the controller later
  req.saveCookie = ( cookie_data ) =>
    req.sandglass.data.cookie = cookie_data

  # add a context object
  req.saveContext = ( index, data ) =>
    req.sandglass.context[ index ] = data

  # save the authenticated user
  req.saveUser = ( user ) =>
    req.sandglass.user = user

  next()

module.exports = prepare_request
