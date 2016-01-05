define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      price: 10
      time: 8
      discount: 100
      remission: 0
      uid: ''
      locs: null
      _userId: null
      _placeId: null
      section: 0
      edit: '<a href="javascript:;">编辑</a>'
      start: '<a href="javascript:;">开机</a>'
      delete: '<a href="javascript:;">删除</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data._userId = "#{data._userId}"
      if data.status is 'fault'
        data.colorStatus = '<span style="color:#ff3c00;">'+data.status+'</span>'
      else
        data.colorStatus = data.status
      data.locs = data.location?.split('-') or null
      data

    idAttribute: 'uid'

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




