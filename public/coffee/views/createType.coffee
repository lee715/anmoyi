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
      @type = opts.type or 'create'
      @render()

    events:
      'submit form': 'onSubmit'
      'click a.del': 'onDelete'

    render: () ->
      if @type is 'edit'
        $.ajax
          url: '/api/types'
          json: true
        .done (res, state) =>
          if state is 'success'
            @$el.html ejs.render(temp, {types: res})
            @
          else 
            @$el.html ejs.render(temp, {})
            @
      else
        @$el.html ejs.render(temp, {types: null})

    showAlert: (state, err) ->
      if state is 'success'
        msg = '操作成功'
      else
        msg = '操作失败'
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
      
    onDelete: (e) ->
      e.preventDefault()
      self = @
      val = @$el.find('select').val()
      $.ajax
        url: "/api/types?name=#{val}"
        data: 
          name: val
        json: true
        method: 'delete'
      .done (res, state) ->
        if state is 'success'
          self.render()
        self.showAlert(state)