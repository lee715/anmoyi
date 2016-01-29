define [
  'backbone'
  'underscore'
  'text!templates/reconciliation.ejs'
  'models/user'
  'models/place'
  'utils'
  'data'
  'ejs'
], (B, _, temp, userModel, placeModel, utils, Data) ->

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
        self.$el.html ejs.render(temp, data)

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

