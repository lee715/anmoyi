define [
  'backbone'
  'underscore'
  'jquery'
  'data'
  'models/user'
], (B, _, $, Data, model) ->

  class Colection extends B.Collection

    model: model

    url: '/api/users'

    initialize: ->
      @on('add', (model, collection) ->
        Data.models[model.id] = model
      )