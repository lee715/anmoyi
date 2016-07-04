define [
  'jquery'
  'backbone'
  'text!templates/confirm.ejs'
], ($, B, temp) ->

  class View extends B.View

    initialize: (opts) ->
      console.log(333, opts)
      @opts = opts or {}
      @opts.btns or= {}
      @render(opts)
      @

    events:
      'click .confirm': 'confirm'
      'click .cancel': 'cancel'

    render: (opts) ->
      console.log(444, opts)
      @$el.html ejs.render(temp, opts)
      @

    confirm: ->
      onConfirm = @opts.onConfirm
      onConfirm and onConfirm()

    cancel: ->
      onCancel = @opts.onCancel
      onCancel and onCancel()

    close: ->
      @$el.remove()

