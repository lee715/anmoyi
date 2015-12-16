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
    role: 0

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
      self.$el.html ejs.render(temp, _.extend({}, defaultVals, data))

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
      return false

