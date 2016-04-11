define [
  'jquery'
  'backbone'
  'utils'
  'text!templates/timepicker.ejs'
], ($, B, utils, temp) ->

  class View extends B.View

    initialize: (opts) ->
      @

    events:
      'submit form': 'submit'

    render: ->
      @$el.html ejs.render(temp)
      @

    submit: ->
      data = utils.formData(@$el.find('form'))
      opts = {}
      if not data.startDate or not data.endDate
        Essage.show
          message: '必须先选择开始时间和结束时间'
          status: 'error'
        , 2000
        return
      startDate = new Date(data.startDate)
      startDate.setHours(data.startTime or 0)
      endDate = new Date(data.endDate)
      endDate.setHours(data.endTime or 24)
      opts.startDate = startDate.toISOString()
      opts.endDate = endDate.toISOString()
      @trigger('submit', opts)
