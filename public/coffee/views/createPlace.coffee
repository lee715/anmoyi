define [
  'backbone'
  'underscore'
  'models/place'
  'text!templates/createPlace.ejs'
  'text!templates/alert.ejs'
  'utils'
  'data'
  'dist'
  'ejs'
], (B, _, Model, temp, alert, utils, Data) ->

  defaultVals = Model::defaults

  class View extends B.View

    initialize: (opts) ->
      opts or= {}
      @type = opts.type or 'create'
      id = opts.params?.id
      @model = Data.models[id] if id
      @render()

    events:
      'submit form': 'onSubmit'

    render: ->
      self = @
      data = {}
      if @type is 'edit' and @model
        data = @model.toJSON()
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
      $.ajax
        url: '/api/places'
        data: data
        json: true
        method: if @type is 'edit' then 'put' else 'post'
      .done (res, state) ->
        if state is 'success'
          self.render()
          self.showAlert(state)
          if self.type is 'create'
            self.showPass(res.password)
      return false

    showPass: (pass) ->
      @$el.find("form").prepend("<p class='text-align:center;color:red;'>密码是："+pass+"</p>")

