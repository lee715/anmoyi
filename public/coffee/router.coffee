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
      'users': -> goto('users')
      'devicesCreate': -> goto('devicesCreate')
      'devicesEdit': 'deviceEdit'
      'usersEdit': 'userEdit'
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

    deviceEdit: ->
      data = utils.query2obj location.search
      goto('devicesEdit', data)

    userEdit: ->
      data = utils.query2obj location.search
      goto('usersEdit', data)

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
        # qrcode = new QRCode 'qrcode',
        #   text: res
        #   width: 256
        #   height: 256
        #   correctLevel: QRCode.CorrectLevel.H
        # console.log qrcode
        # new QRCode($qr[0], res)

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
      query = location.search.slice(1).split('=')[1]
      $.ajax(
        url: "/api/ticket?uid=#{query}"
        method: 'get'
      ).done (res, state) ->
        console.log res
        $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>')
        $('body').html($qr)
        $qr.qrcode
          width: 256
          height: 256
          text: res


