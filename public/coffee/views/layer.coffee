define [
  'jquery'
  'backbone'
  'data'
  'text!templates/layer.ejs'
  'views/devices'
  'views/users'
  'views/createDevice'
  'views/createUser'
  'views/login'
], ($, B, Data, layerTemp, devicesView, usersView, createDeviceView, createUserView, loginView) ->

  class Layer extends B.View

    initialize: (options) ->
      @options = options or {}
      @params = @options.params
      @_route = @options.route
      @_views = {}
      @render()
      @

    events:
      'click .route': 'routeHdl'

    routeHdl: (e) ->
      url = $(e.target).data('url')
      Data.route(url)

    render: ->
      @$el.html ejs.render(layerTemp,
        isLogin: !!Data.user
        isRoot: Data.user?.role is 9
      )
      @$main = @$el.find('#mainSection')
      @renderSubView()
      @

    switchTo: (route, params) ->
      @params = params
      @_route = route
      @render()

    renderSubView: ->
      switch @_route
        when 'devices'
          # if @_views.devices
          #   @$main.html @_views.devices.el
          # else
          @_views.devices = new devicesView
            el: @$main[0]
        when 'users'
          # if @_views.devices
          #   @$main.html @_views.devices.el
          # else
          @_views.users = new usersView
            el: @$main[0]
        when 'devicesCreate'
          # if @_views.createDevice
          #   @$main.html @_views.createDevice.el
          # else
          @_views.createDevice = new createDeviceView
            el: @$main[0]
        when 'usersCreate'
          # if @_views.createUser
          #   @$main.html @_views.createUser.el
          # else
          @_views.createUser = new createUserView
            el: @$main[0]
        when 'login'
          # if @_views.login
          #   @$main.html @_views.login.el
          # else
          @_views.login = new loginView
            el: @$main[0]
        when 'devicesEdit'
          # if @_views.editDevice
          #   @$main.html @_views.editDevice.render(@params).el
          # else
          @_views.editDevice = new createDeviceView
            el: @$main[0]
            params: @params
            type: 'edit'
        when 'usersEdit'
          # if @_views.editDevice
          #   @$main.html @_views.editDevice.render(@params).el
          # else
          @_views.editUser = new createUserView
            el: @$main[0]
            params: @params
            type: 'edit'

