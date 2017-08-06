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
    title: '微信手续费（0.6%）'
  ,
    field: 'agentFeeStr'
    title: '场地分成金额（元）'
  ,
    field: 'salesFeeStr'
    title: '业务员分成（元）'
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
        data.totals[3] = +data.totals[0] + +data.totals[1] + +data.totals[2]
        tableData = []
        data.totals.forEach((one, i) =>
          rt = {}
          rt.month = data.months[i] || '总计'
          rt.total = one
          rt.wxFee = (one * 0.006).toFixed(2)
          if data.place.agentMode is 'percent'
            rt.agentFee = (one * 0.994 * data.place.agentCount / 100).toFixed(2)
            rt.agentFeeStr = "#{rt.agentFee}(#{data.place.agentCount}%)"
          else
            rt.agentFee = data.place.agentCount
            rt.agentFeeStr = data.place.agentCount + "(固定分成)"
          rt.adminFee = (one * 0.994 - rt.agentFee).toFixed(2)
          if data.place.salesmanMode is 'percent'
            rt.salesFee = (rt.adminFee * data.place.salesmanCount / 100).toFixed(2)
            rt.salesFeeStr = "#{rt.salesFee}(#{data.place.salesmanCount}%)"
          else
            rt.salesFee = data.place.salesmanCount
            rt.salesFeeStr = data.place.salesmanCount + "(固定分成)"
          if Data.isRoot()
            rt.count = (rt.adminFee - rt.salesFee).toFixed()
          else if Data.isAgent()
            rt.count = rt.agentFee
          else
            rt.count = rt.salesFee
          tableData.push(rt)
        )
        self.$el.html ejs.render(temp, data)
        @$table = $('#recTable')
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
      else if user.role in ['root', 'salesman']
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

