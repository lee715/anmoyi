define [], ->
  window.data = Data =
    models: {}
    dontHandle: ->
      return /^\/url/.test(location.pathname)
    checkLogin: (route, cb) ->
      if route is 'login'
        cb()
      else if @user
        cb()
      else
        @login()
    home: ->
      return if @dontHandle()
      if @user
        role = @user.role
        url = if role is 'place' then '/reconciliation' else '/devices'
        @app.navigate(url,
          trigger: true
        )
      else
        @login()
    login: ->
      return if @dontHandle()
      @app.navigate('/login',
        trigger: true
      )
    route: (url) ->
      console.log 'Data.route', url
      @app.navigate(url,
        trigger: true
      )
    isRoot: ->
      return @user.role is 9
  return Data