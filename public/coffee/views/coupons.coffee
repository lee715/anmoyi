define [
  'backbone'
  'underscore'
  'views/confirm'
  'text!templates/coupons.ejs'
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

    render: (data) ->
      @$el.html ejs.render(temp, {coupons: data})

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      $.ajax
        url: '/api/coupons'
        data: data
        json: true
        method: 'post'
      .done (res, state) ->
        if state is 'success'
          self.render(res)
      return false
      