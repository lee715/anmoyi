define [
  'backbone'
  'underscore'
  'data'
  'models/device'
  'text!templates/createDevice.ejs'
  'text!templates/alert.ejs'
  'utils'
  'dist'
  'ejs'
], (B, _, Data, deviceModel, temp, alert, utils) ->

  defaultVals = deviceModel::defaults

  class Seletor extends B.View

    initialize: (opts) ->
      opts or= {}
      @type = opts.type or 'create'
      id = opts.params?.id
      @model = Data.models[id] if id
      @render()

    events:
      'submit form': 'onSubmit'

    render: (data) ->
      self = @
      switch @type
        when 'create'
          @fetchUsers (users) ->
            self.users = users
            data or= {}
            data.users = users
            self.fetchPlaces (places) ->
              data.places = places
              self.$el.html ejs.render(temp, _.extend({}, defaultVals, data))
              self.$el.find('#distpicker').distpicker()
        when 'edit'
          data = @model.toJSON()
          if Data.isRoot()
            @fetchUsers (users) ->
              data.users = users.map (user) ->
                user._id = "#{user._id}"
                user
              self.fetchPlaces (places) ->
                data.places = places
                self.$el.html ejs.render(temp, _.extend({}, defaultVals, data))
                self.$el.find('#distpicker').distpicker()
          else
            data.users = null
            self.$el.html ejs.render(temp, _.extend({}, defaultVals, data))
            self.$el.find('#distpicker').distpicker()
      @

    refresh: (data) ->
      return unless @users
      data or= @model.toJSON()
      data.users = @users
      @$el.html ejs.render(temp, _.extend({}, defaultVals, data))

    showAlert: (state, err) ->
      switch @type
        when 'create'
          if state is 'success'
            msg = '创建成功，你可以继续创建'
          else
            msg = '创建失败，请检查表单'
        when 'edit'
          if state is 'success'
            msg = '编辑成功!'
          else
            msg = '编辑失败，请检查参数'
      Essage.show
        message: msg
        status: state
      , 2000
      # if @type is 'edit' and state is 'success'
      #   Data.home()

    fetchUsers: (cb) ->
      data = {}
      $.ajax
        url: '/api/agents'
        method: 'get'
        json: true
      .done (res, state) ->
        if state is 'success'
          cb(res)

    fetchPlaces: (cb) ->
      data = {}
      $.ajax
        url: '/api/places'
        method: 'get'
        json: true
      .done (res, state) ->
        if state is 'success'
          cb(res)

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      if data.province and data.city and data.district
        data.location = "#{data.province}-#{data.city}-#{data.district}"
        delete data.province
        delete data.city
        delete data.district
      data._id = @model.id if @model
      $.ajax
        url: "/api/devices/#{@type || 'create'}"
        data: data
        json: true
        method: if @type is 'edit' then 'put' else 'post'
      .done (res, state) ->
        if state is 'success'
          self.model.set(data) if self.model
          self.refresh()
          self.showAlert(state)
      return false

