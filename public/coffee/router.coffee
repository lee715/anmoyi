define [
  'data'
  'backbone'
  'jquery'
  'qrcode'
  'views/layer'
  'views/login'
  'utils'
], (Data, B, $, qr, layerView, loginView, utils) ->

  goto = (route, params) ->
    Data.handleQuery()
    Data.checkLogin(route, ->
      if Data.layer
        Data.layer.switchTo(route, params)
      else
        Data.layer = new layerView
          'route': route
          params: params
        $('body').prepend(Data.layer.el)
    )


  class Router extends B.Router

    initialize: ->
      # @route /devicesEdit\/([^\/]+)/, 'deviceEdit'

    routes:
      'login': 'login'
      'devices': -> goto('devices')
      'orders': -> goto('orders')
      'places': -> goto('places')
      'users': -> goto('users')
      'reconciliation': -> goto('reconciliation')
      'devicesCreate': -> goto('devicesCreate')
      'devicesEdit': -> goto('devicesCreate')
      'placesCreate': -> goto('placesCreate')
      'placesEdit': -> goto('placesCreate')
      'usersEdit': -> goto('usersEdit')
      # 'devices/:action/:_id': 'deviceEdit'
      'usersCreate': -> goto('usersCreate')
      'urlqrcode': 'qrcode'
      'urlauth': 'wx_auth'
      'urlticket': 'wx_ticket'
      '*paramString': 'login'
      # 'devices/:_id': (id) ->
      #   console.log id
      #   goto('devices/edit', id)

    login: (params) ->
      goto('login')

    qrcode: ->
      $.ajax(
        url: '/api/qrcode'
        method: 'get'
      ).done (res, state) ->
        console.log res
        $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>')
        $('body').html($qr)
        $qr.qrcode
          width: 256
          height: 256
          text: res

    wx_auth: ->
      $.ajax(
        url: '/api/auth'
        method: 'get'
      ).done (res, state) ->
        console.log res
        $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>')
        $('body').html($qr)
        $qr.qrcode
          width: 256
          height: 256
          text: res

    wx_ticket: ->
      obj = utils.query2obj(location.search)
      if obj.uid
        query = "uid=#{obj.uid}"
      else if obj._placeId
        query = "_placeId=#{obj._placeId}"
      $.ajax(
        url: "/api/ticket?#{query}"
        method: 'get'
      ).done (res, state) ->
        $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>')
        $('body').html($qr)
        $qr.qrcode
          width: 256
          height: 256
          text: res


