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

    initialize: ->
      @on('add', (model, collection) ->
        Data.models[model.id] = model
      )