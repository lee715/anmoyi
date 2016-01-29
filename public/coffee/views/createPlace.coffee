define [
  'backbone'
  'underscore'
  'models/place'
  'views/confirm'
  'text!templates/createPlace.ejs'
  'text!templates/alert.ejs'
  'utils'
  'data'
  'dist'
  'ejs'
], (B, _, Model, ConfirmView, temp, alert, utils, Data) ->

  defaultVals = Model::defaults

  class View extends B.View

    initialize: (opts) ->
      opts or= {}
      @type = opts.type or 'create'
      id = Data.getPlaceId()
      if id
        @type = 'edit'
        @model = Data.models[id]
        unless @model
          return Data.home()
      @render()

    events:
      'submit form': 'onSubmit'

    render: ->
      self = @
      @fetchUsers (users) =>
        self.users = users
        data = {}
        if @type is 'edit' and @model
          data = @model.toJSON()
        data.users = users
        data = _.extend({}, defaultVals, data)
        data.type = @type
        self.$el.html ejs.render(temp, data)
        self.$el.find('#distpicker').distpicker()
      @

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
      if @type is 'edit' and state is 'success'
        setTimeout ->
          Data.home()
        , 2000

    fetchUsers: (cb) ->
      data = {}
      $.ajax
        url: '/api/agents'
        method: 'get'
        json: true
      .done (res, state) ->
        if state is 'success'
          cb(res)

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      data.contacts = [
        name: data.contacts_name
        phone: data.contacts_phone
      ,
        name: data.contacts_name_bk
        phone: data.contacts_phone_bk
      ]
      if @model
        data._id = @model.id
      $.ajax
        url: '/api/places'
        data: data
        json: true
        method: if @type is 'edit' then 'put' else 'post'
      .done (res, state) ->
        if state is 'success'
          self.render()
          if self.type is 'create'
            view = new ConfirmView(
              title: '场地创建'
              content: '场地创建成功，场地方密码为 ' + res.password + '。请妥善保存。'
              btns:
                confirm: '回到场地列表'
                cancel: '继续创建'
              onConfirm: ->
                Data.route('/places')
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)
          else
            self.showAlert(state)
        else
          self.showAlert(state)

      return false

    showPass: (pass) ->
      @$el.find("form").prepend("<p class='text-align:center;color:red;'>密码是："+pass+"</p>")

