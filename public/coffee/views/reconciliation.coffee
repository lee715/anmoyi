define [
  'backbone'
  'underscore'
  'text!templates/reconciliation.ejs'
  'models/user'
  'models/place'
  'utils'
  'data'
  'ejs'
  'table'
], (B, _, temp, userModel, placeModel, utils, Data) ->

  columns = [
    field: 'month'
    title: '月份'
  ,
    field: 'total'
    title: '总金额'
  ,
    field: 'wxFee'
    title: '微信手续费'
  ,
    field: 'placeFee'
    title: '分成金额'
  ,
    field: 'salesFee'
    title: '业务员分成'
  ,
    field: 'count'
    title: '实际所得'
  ]

  class View extends B.View

    initialize: ->
      @render()

    render: ->
      self = @
      @fetch (err, data) ->
        month = (new Date).getMonth() + 1
        year = year1 = year2 = (new Date).getFullYear()
        map = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        if month is 1
          year1 = year - 1
        if month <= 2
          year2 = year - 1
        data.months = [
          "#{year}年#{month}月"
          "#{year1}年#{map[(month+11)%12]}月"
          "#{year2}年#{map[(month+10)%12]}月"
        ]
        tableData = []
        data.totals.forEach((one, i) =>
          rt = {}
          rt.month = data.months[i]
          rt.total = one
          rt.wxFee = (one * 0.06).toFixed(2)
          if data.place.agentMode is 'percent'
            rt.agentFee = (rt.wxFee * data.place.agentCount / 100).toFixed(2)
          else
            rt.agentFee = data.place.agentCount
          if data.place.salesmanMode is 'percent'
            rt.salesFee = (rt.agentFee * data.place.salesmanCount / 100).toFixed(2)
          else
            rt.salesFee = data.place.salesmanCount
          rt.count = rt.agentFee - rt.salesFee
          tableData.push(rt)
        )
        tableData.push(_.reduce(tableData, (a, b) ->
          return a + b
        ))
        self.$el.html ejs.render(temp, data)
        @$table = @$el.find('#recTable')
        @$table.bootstrapTable
          columns: columns
          striped: true
          pagination: true
          pageSize: 50
        @$table.bootstrapTable('load', tableData)
      @

    showAlert: (state, err) ->
      if state is 'success'
        return Data.app.navigate('/devices')
      else
        note = err or '登陆失败，请检查'
        Essage.show
          message: note
          status: 'error'

    fetch: (callback) ->
      user = Data.user.toJSON()
      if user.role is 'agent'
        @fetchPlace (err, place) =>
          @fetchTotals (err, totals) ->
            data =
              agent: user
              place: place
              totals: totals
            callback(null, data)
      else if user.role is 'place'
        @fetchAgent user._agentId, (err, agent) =>
          @fetchTotals (err, totals) ->
            data =
              agent: agent
              place: user
              totals: totals
            callback(null, data)
      else if user.role is 'root'
        @fetchPlace (err, place) =>
          @fetchAgent place._agentId, (err, agent) =>
            @fetchTotals (err, totals) ->
              data =
                agent: agent
                place: place
                totals: totals
              callback(null, data)

    fetchAgent: (_agentId, callback) ->
      $.ajax
        url: "/api/agents/#{_agentId}"
        json: true
      .done (res, state) ->
        if state is 'success'
          model = new userModel(res)
          callback(null, model.toJSON())

    fetchPlace: (callback) ->
      $.ajax
        url: "/api/places/#{Data.getPlaceId()}"
        json: true
      .done (res, state) ->
        if state is 'success'
          model = new placeModel(res)
          callback(null, model.toJSON())

    fetchTotals: (callback) ->
      $.ajax
        url: "/api/reconciliation/#{Data.getPlaceId()}"
        json: true
      .done (res, state) ->
        if state is 'success'
          callback(null, res)

