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
      edit: '<a href="javascript:;">编辑</a>'
      refund: '<a href="javascript:;">退款</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data._userId = "#{data._userId or ''}"
      switch data.mode
        when 'WX'
          data.mode_zh = '微信支付'
        when 'WX_EXCHARGE'
          data.mode_zh = '充值'
        when 'API'
          data.mode_zh = '余额扣费'
        else
          data.mode_zh = '投币支付'
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




