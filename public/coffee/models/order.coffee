define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      money: 0
      time: 0
      status: "PREPAY"
      mode: "TB"
      openId: ''
      uid: ''
      _userId: ''
      deviceStatus: 'idle'
      serviceStatus: ''
      created: ''
      edit: '<a href="javascript:;">Edit</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data._userId = "#{data._userId or ''}"
      data.mode_zh = if data.mode is 'WX' then '微信支付' else "投币支付"
      data.created = (new Date(data.created)).toLocaleString()
      data

    idAttribute: '_id'

    update: (params) ->
      $.ajax(
        url: "/orders/#{@id}"
        method: 'put'
        data: params
      ).done((res, state) ->
        if state is 'success'
          res.uid = "res.uid"
          @set(res)
      )




