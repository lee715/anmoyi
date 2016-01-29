define [
  'backbone'
  'underscore'
  'text!templates/login.ejs'
  'text!templates/warn.ejs'
  'utils'
  'data'
  'ejs'
], (B, _, temp, warn, utils, Data) ->

  AuthErr =
    user: '用户不存在'
    password: '密码错误'

  class View extends B.View

    initialize: ->
      @render()

    events:
      'submit form': 'onSubmit'

    render: ->
      self = @
      self.$el.html ejs.render(temp)
      @$form = @$el.find('form')

    showAlert: (state, err) ->
      if state is 'success'
        return Data.app.navigate('/devices')
      else
        note = err or '登陆失败，请检查'
        Essage.show
          message: note
          status: 'error'

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      $.ajax
        url: '/api/login'
        data: data
        json: true
        method: 'post'
      .done (res, state) ->
        Data.storeUser(res)
        Data.home()
      .fail (req, state, err) ->
        if req.status is 401
          self.showAlert(state, AuthErr[req.responseText])
      return false

