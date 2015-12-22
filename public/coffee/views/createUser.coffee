define [
  'backbone'
  'underscore'
  'text!templates/createUser.ejs'
  'text!templates/alert.ejs'
  'utils'
  'data'
  'ejs'
], (B, _, temp, alert, utils, Data) ->

  urlMap =
    create: '/api/users/create'
    edit: '/api/users/edit'

  defaultVals =
    name: ''
    company: ''
    email: ''
    phone: ''
    location: ''
    role: 'salesman'
    mailAddress: ''
    qq: ''
    bankName: ''
    bankAccount: ''
    roles: ['agent', 'salesman', 'admin']

  class View extends B.View

    initialize: (opts) ->
      opts or= {}
      @type = opts.type or 'create'
      id = opts.params?.id
      @model = Data.models[id] if id
      @render()

    events:
      'submit form': 'onSubmit'
      'change select[name="role"]': 'refreshAddition'

    render: ->
      self = @
      data = {}
      if @type is 'edit' and @model
        data = @model.toJSON()
      data = _.extend({}, defaultVals, data)
      data.type = @type
      self.$el.html ejs.render(temp, data)
      @$addition = @$el.find('#createUserAddition')
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
      $.ajax
        url: urlMap[@type]
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

    refreshAddition: (e) ->
      val = $(e.target).val()
      if val is 'agent'
        @$addition.removeClass('hide')
      else
        if @type is 'create'
          @$addition.find('input').val('')
        @$addition.addClass('hide')

    showPass: (pass) ->
      @$el.find("form").prepend("<p>密码是："+pass+"</p>")

