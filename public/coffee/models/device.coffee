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
      disabled: false
      section: 0
      type: 'normal'
      disableStr: '<a href="javascript:;">启/禁用</a>'
      edit: '<a href="javascript:;">编辑</a>'
      start: '<a href="javascript:;">开机</a>'
      delete: '<a href="javascript:;">删除</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data._userId = "#{data._userId}"
      if data.disabled
        data.disableStr = '<a href="javascript:;">启用</a>'
      else
        data.disableStr = '<a href="javascript:;">禁用</a>'
      if data.status is 'fault'
        data.colorStatus = '<span style="color:#ff3c00;">关闭</span>'
      else if data.status is 'work'
        data.colorStatus = '工作'
      else if data.status is 'idle'
        data.colorStatus = '<span style="color:#00ff00;">空闲</span>'
      data.locs = data.location?.split('-') or null
      if data.total
        data.today = (data.total.today.TB or 0).toFixed(2) + '/' + (data.total.today.WX or 0).toFixed(2)
        data.yestoday = (data.total.yestoday.TB or 0).toFixed(2) + '/' + (data.total.yestoday.WX or 0).toFixed(2)
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




