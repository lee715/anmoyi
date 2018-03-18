define ['utils', 'models/user'], (utils, userModel) ->
  window.data = Data =
    models: {}
    query: {}
    getPlaceId: ->
      return @_placeId or @query._placeId
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
        role = @user.get('role')
        @_placeId = @user.id if role is 'place'
        if role is 'place'
          url = '/reconciliation'
        else if role is 'server'
          url = '/orders'
        else
          url = '/places'
        @app.navigate(url,
          trigger: true
        )
      else
        @login()
    handleQuery: ->
      query = utils.query2obj location.search
      @query = query
    login: ->
      return if @dontHandle()
      @app.navigate('/login',
        trigger: true
      )
    route: (url) ->
      console.log 'Data.route', url
      if @user.get('role') is 'place' and url isnt '/usersEdit'
        return @home()
      @app.navigate(url,
        trigger: true
      )
    storeUser: (user) ->
      @user = new userModel(user)
      if user.role is 'place'
        @_placeId = user._id
    isRoot: ->
      return @user.get('role') is 'root'
    refresh: ->
      location.reload()
    order: (order, uid, time) ->
      $.ajax
        url: "/api/devices/order"
        data:
          uid: uid
          order: order
          time: time
        json: true
      .done((res, state) ->
        Essage.show
          message: if state is 'success' then '开机成功' else '开机失败'
          status: state
        , 2000
      ).error ->
        Essage.show
          message: '开机失败'
          status: 'error'
        , 2000
    del: (type, id) ->
      self = @
      $.ajax
        url: "/api/#{type}s"
        data: _id: id
        method: 'delete'
        json: true
      .done((res, state) ->
        Essage.show
          message: if state is 'success' then '删除成功' else '删除失败'
          status: state
        , 2000
        setTimeout(->
          self.refresh()
        , 2000)
      ).error ->
        Essage.show
          message: '删除失败'
          status: 'error'
        , 2000
        setTimeout(->
          self.refresh()
        , 2000)
  return Data