define [
  'backbone'
  'underscore'
  'jquery'
  'data'
  'models/order'
], (B, _, $, Data, model) ->

  class Colection extends B.Collection

    model: model

    url: '/api/orders'

    initialize: ->
      @on('add', (model, collection) ->
        Data.models[model.id] = model
      )