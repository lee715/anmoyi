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

    fetch: (opts) ->
      $.ajax(
        url: '/api/orders'
        data: opts.data
        method: 'GET'
        json: true
      ).done((data, state) =>
        m = new model()
        data = data.map((item) ->
          return m.parse(item)
        )
        if state is 'success'
          @reset(data)
          opts.success and opts.success(@, data)
        else
          opts.error and opts.error(data, state)
      )