define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      place: ''
      location: ''
      price: '10/8'
      discount: 100
      remission: 0
      uid: ''
      locs: null
      _userId: null
      edit: '<a href="javascript:;">Edit</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data._userId = "#{data._userId}"
      data.locs = data.location?.split('-') or null
      data

    idAttribute: '_id'

    update: (params) ->
      $.ajax(
        url: "/devices/#{@id}"
        method: 'put'
        data: params
      ).done((res, state) ->
        if state is 'success'
          res.uid = "res.uid"
          @set(res)
      )




