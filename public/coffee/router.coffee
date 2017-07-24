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
      'places/detail': -> goto('placesDetail')
      'users': -> goto('users')
      'reconciliation': -> goto('reconciliation')
      'devicesCreate': -> goto('devicesCreate')
      'devicesEdit': -> goto('devicesCreate')
      'placesCreate': -> goto('placesCreate')
      'placesEdit': -> goto('placesCreate')
      'usersEdit': -> goto('usersEdit')
      'typesCreate': -> goto('typesCreate')
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
        $qr = $('<div id="qrcode" style="width:256px;height:256px;position:relative;"></div>')
        $('body').append($qr)
        $qr.qrcode
          width: 256
          height: 256
          text: res
        # $qr.append('<img src="/tmp/static/images/WechatIMG123.png" style="width:70px;height:70px;position:absolute;top:50%;left:50%;margin-top:-40px;margin-left:-40px;border: solid white 5px;"></img>')
        $qr.append('<span>设备编号： ' + obj.uid + '<span>')
        c = $('canvas')[0]
        ctx = c.getContext("2d")
        img = new Image()
        img.src = "/tmp/static/images/WechatIMG23.jpeg"
        img.width = 40
        img.height = 40
        img.border = "solid white 5px"
        ctx.drawImage(img, 88, 88, 70, 70);


