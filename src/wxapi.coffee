_ = require('lodash')
db = require('limbo').use('anmoyi')
WX_API = require('./weixin/api')
MP_API = require('./weixin/mpApi')
WXPay = require('weixin-pay')
async = require('async')
wxReply = require('./weixin/message')
redis = require('./services/redis')
Promise = require('bluebird')
sockSrv = require('./services/socket')

queryOrderByTimes = (_orderId, times, callback) ->
  _doOne = ->
    WX_API.queryOrder out_trade_no: "#{_orderId}", (err, wx_order) ->
      console.log 'times', times, wx_order.trade_state
      if wx_order.trade_state isnt 'SUCCESS'
        times--
        if times > 0
          setTimeout(_doOne, 1000)
        else
          callback(null, false)
      else
        callback(null, true)
  _doOne()
queryOrderByTimesAsync = Promise.promisify(queryOrderByTimes)

class API

  """
  响应微信消息
  """
  handleMessage: (req, callback) ->
    { _message } = req
    async.waterfall [
      (next) ->
        WX_API.checkSingle _message, next
    ], (err) ->
      wxReply _message

    callback(null, '')

  @::handleMessage.route = ['post', '/wx/message']
  @::handleMessage.before = [
    (req, res, next) ->
      message = req.body.xml
      msg = {}
      for key, val of message
        msg[key] = val?[0]
      req._message = msg
      next()
  ]

  payTestView: (req, callback) ->
    openid = req.query.openid
    WX_API.getPayInfoAsync(openid)
    .then (info) ->
      db.place.findOneAsync
        _id: info._placeId
      .then (place) ->
        info.placeName = place.name
        info
    .then (info) ->
      info.openid = openid
      if info.status in ['idle', 'work']
        db.order.createAsync
          money: info.cost
          time: info.time
          openId: openid
          deviceStatus: info.status
          uid: info.uid
          _userId: info._userId
          _placeId: info._placeId
          mode: "WX"
        .then (order) ->
          WX_API.getBrandWCPayRequestParamsAsync openid, "#{order._id}", info.cost
          .then (args) ->
            info.payargs = args
            info.order = "#{order._id}"
            req.res.render('pay', info)
      else
        info.payargs = {}
        req.res.render('pay', info)
    .catch ->
      req.res.send('system error, please try later')
  @::payTestView.route = ['get', '/view/test/h5pay']

  payView: (req, callback) ->
    openid = req.query.openid
    WX_API.getPayInfoAsync(openid)
    .then (info) ->
      db.place.findOneAsync
        _id: info._placeId
      .then (place) ->
        info.placeName = place.name
        info
    .then (info) ->
      info.openid = openid
      if info.status in ['idle', 'work']
        db.order.createAsync
          money: info.cost
          time: info.time
          openId: openid
          deviceStatus: info.status
          uid: info.uid
          _userId: info._userId
          _placeId: info._placeId
          mode: "WX"
        .then (order) ->
          WX_API.getBrandWCPayRequestParamsAsync openid, "#{order._id}", info.cost * 100  # 微信金额单位为分
          .then (args) ->
            info.payargs = args
            info.order = "#{order._id}"
            req.res.render('pay', info)
      else
        info.payargs = {}
        req.res.render('pay', info)
    .catch ->
      req.res.send('system error, please try later')
  @::payView.route = ['get', '/pay/v1/h5pay']

  recharge: (req, callback) ->
    unless money and openid and _placeId
      return callback(new Error('params error'))
    money = req.query.money
    openid = req.query.openid
    _placeId = req.query._placeId
    db.order.createAsync
      money: money
      openId: openid
      _placeId: _placeId
      mode: "WX_RECHARGE"
    .then (order) ->
      WX_API.getBrandWCPayRequestParamsAsync openid, "#{order._id}", money * 100
      .then (args) ->
        callback(null, args)
    .catch (e) ->
      callback(e)
  @::recharge.route = ['get', '/pay/v1/recharge']

  pageView: (req, callback) ->
    openid = req.query.openid
    _placeId = req.query._placeId
    info = {}
    db.place.findOneAsync
      _id: _placeId
    .then (place) ->
      info.placeName = place.name
      info.openid = openid
      db.device.findAsync
        _placeId: _placeId
    .then (devices) ->
      info.devices = _.map(devices, (device) -> device.toJSON())
      db.alien.findOneAsync
        openId: openid
    .then (alien) ->
      info.user = alien.toJSON()
      req.res.render('payWithPlace', info)
    .catch ->
      req.res.send('system error, please try later')
  @::pageView.route = ['get', '/pay/v1/h5page']

  wxExcharge: (req, callback) ->
    {_orderId, openid} = req.query
    unless openid and _orderId
      return callback(new Error('paramErr'))
    order = null
    alien = null
    db.alien.findOneAsync openId: openid
    .then (_alien) ->
      unless _alien
        throw new Error('alien isnt found')
      alien = _alien
      db.order.findOneAsync
        _id: _orderId
    .then (_order) ->
      order = _order
      if order.status isnt 'SUCCESS'
        queryOrderByTimesAsync(order._id, 3)
        .then (state) ->
          console.log 'state', state
          throw new Error('confirm failed') unless state
        .then ->
          order.status = "SUCCESS"
          order.saveAsync()
        .then ->
          alien.money += order.money
          alien.saveAsync()
    .then ->
      callback(null, {state: 'ok', money: alien.money})
    .catch callback
  @::wxExcharge.route = ['get', '/wx/excharge']

  confirmAndStart: (req, callback) ->
    {_orderId, uid, openid} = req.query
    console.log 'confirmAndStart', _orderId, uid, openid
    unless uid and _orderId
      return callback(new Error('paramErr'))
    order = null
    db.order.findOneAsync
      _id: _orderId
    .then (_order) ->
      order = _order
      if order.status isnt 'SUCCESS'
        queryOrderByTimesAsync(order._id, 3)
        .then (state) ->
          console.log 'state', state
          throw new Error('confirm failed') unless state
    .then ->
      order.status = "SUCCESS"
      order.serviceStatus = 'PAIED'
      order.saveAsync()
    .then ->
      redis.getAsync "ORDER.COMMAND.LOCK.#{_orderId}"
    .then (lock) ->
      throw new Error('order is handling') if lock
      redis.setexAsync "ORDER.COMMAND.LOCK.#{_orderId}", 60*10, 1
    .then ->
      sockSrv.startAsync(uid, order.time)
      .then (state) ->
        throw new Error('start failed') unless state
        order.serviceStatus = 'STARTED'
        order.saveAsync()
      .then ->
        db.device.updateAsync
          uid: uid
        , status: 'work'
        ,
          upsert: false
          new: false
      .then ->
        callback(null, 'ok')
    .then ->
      redis.del "ORDER.COMMAND.LOCK.#{_orderId}"
    .catch (e) ->
      console.log e.stack
      callback(e)
  @::confirmAndStart.route = ['get', '/wx/order/run']

  orderStatus: (req, callback) ->
    order = req.query.order
    expect = req.query.expect
    unless order
      return callback(new Error('order is required'))
    db.order.findOneAsync
      _id: order
    .then (order) ->
      if expect and order.status isnt expect
        WX_API.queryOrderAsync out_trade_no: "#{order._id}"
        .then (wx_order) ->
          if wx_order.trade_state isnt order.status
            order.status = wx_order.trade_state
            if wx_order.trade_state is 'SUCCESS'
              order.serviceStatus = "PAIED"
            order.save()
          wx_order.trade_state
      else
        order.status
    .then (status) ->
      callback(null, status)
    .catch (e) ->
      console.log e
      callback(e)
  @::orderStatus.route = ['get', '/wx/order/status']

module.exports = new API
