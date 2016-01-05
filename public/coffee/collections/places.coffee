define [
  'backbone'
  'underscore'
  'jquery'
  'data'
  'models/place'
], (B, _, $, Data, model) ->

  class Colection extends B.Collection

    model: model

    url: '/api/places/statistic'

    initialize: ->
      @on('add', (model, collection) ->
        Data.models[model.id] = model
      )

    querySection: (opts) ->
      self = @
      data = opts
      data.type = 'place'
      $.ajax
        url: "/api/section"
        data: data
        json: true
      .done((res, state) ->
        Object.keys(res).forEach (key) ->
          self.get(key).set('section', res[key])
      )
