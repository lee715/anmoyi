define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      name: ''
      location: ''
      province: ''
      city: ''
      district: ''
      phone: ''
      email: ''
      company: ''
      mailAddress: ''
      mode: ''
      qq: ''
      price: ''
      time: ''
      bankName: ''
      bankAccount: ''
      _salesmanId: ''
      _agentId: ''
      agentMode: 'percent'
      agentCount: 0
      salesmanMode: 'percent'
      salesmanCount: 0
      section: 0
      discount: 100
      remission: 0
      contacts: [{}, {}]
      p: 100
      moneys: [0,0,0,0,0,0]
      device:
        total: 0
        normal: 0
      edit: '<a href="javascript:;">编辑</a>'
      delete: '<a href="javascript:;">删除</a>'
      reconciliation: '<a href="javascript:;">对账</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data.address = "#{data.province}-#{data.city}-#{data.district}"
      normal = data.device.normal
      total = data.device.total
      if normal is total
        data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#259b24;'>#{normal}/#{total}</a>"
      else if normal is 0
        data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#ff3c00;'>#{normal}/#{total}</a>"
      else
        data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#ff9800;'>#{normal}/#{total}</a>"
      data.today = data.moneys[0].toFixed(2)
      data.yestoday = data.moneys[1].toFixed(2)
      data.thisWeek = data.moneys[2].toFixed(2)
      data.lastWeek = data.moneys[3].toFixed(2)
      # data.thisMonth = data.moneys[4].toFixed(2)
      # data.lastMonth = data.moneys[5].toFixed(2)
      data

    idAttribute: '_id'

    update: (params) ->
      $.ajax(
        url: "/places/#{@id}"
        method: 'put'
        data: params
      ).done((res, state) ->
        if state is 'success'
          @set(res)
      )




