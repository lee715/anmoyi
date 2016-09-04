define [
  'backbone'
  'underscore'
  'views/confirm'
  'text!templates/createType.ejs'
  'text!templates/alert.ejs'
  'utils'
  'data'
  'dist'
  'ejs'
], (B, _, ConfirmView, temp, alert, utils, Data) ->

  class View extends B.View

    initialize: (opts) ->
      @render()

    events:
      'submit form': 'onSubmit'

    render: ->
      @$el.html ejs.render(temp, {})
      @

    showAlert: (state, err) ->
      if state is 'success'
        msg = '创建成功，你可以继续创建'
      else
        msg = '创建失败，请检查表单'
      Essage.show
        message: msg
        status: state
      , 2000

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      $.ajax
        url: '/api/types'
        data: data
        json: true
        method: 'post'
      .done (res, state) ->
        if state is 'success'
          self.render()
        self.showAlert(state)

      return false
