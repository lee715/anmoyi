define [
  'backbone'
  'underscore'
  'jquery'
  'data'
  'models/device'
], (B, _, $, Data, model) ->

  class Colection extends B.Collection

    model: model

    url: '/api/devices'

    initialize: (models, opts) ->
      opts or= {}
      if opts._placeId
        @url = @url + '?_placeId=' + opts._placeId
      @on('add', (model, collection) ->
        Data.models[model.id] = model
      )

    querySection: (opts) ->
      self = @
      data = opts
      data.type = 'device'
      data._ = Date.now()
      $.ajax
        url: "/api/section"
        data: data
        json: true
      .done((res, state) ->
        Object.keys(res).forEach (key) ->
          self.get(key).set('section', res[key])
      )