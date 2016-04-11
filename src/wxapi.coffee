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
util = require('./services/util')

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
      console.log('11', _message)
      if _message.msgtype is 'text'
        # req.res.writeHead(200)
        req.res.set('Content-Type', 'text/xml')
        console.log(util.json2xml(
          ToUserName: "<![CDATA[#{_message.tousername}]]>"
          FromUserName: "<![CDATA[#{_message.fromusername}]]>"
          CreateTime: _message.createtime
          MsgType: '<![CDATA[transfer_customer_service]]>'
        ))
        req.res.end(util.json2xml(
          ToUserName: "<![CDATA[#{_message.tousername}]]>"
          FromUserName: "<![CDATA[#{_message.fromusername}]]>"
          CreateTime: _message.createtime
          MsgType: '<![CDATA[transfer_customer_service]]>'
        ))
        return
      else
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
    openId = req.query.openId
    WX_API.getPayInfoAsync(openId)
    .then (info) ->
      db.place.findOneAsync
        _id: info._placeId
      .then (place) ->
        info.placeName = place.name
        info
    .then (info) ->
      info.openId = openId
      if info.status in ['idle', 'work']
        db.order.createAsync
          money: info.cost
          time: info.time
          openId: openId
          deviceStatus: info.status
          uid: info.uid
          _userId: info._userId
          _placeId: info._placeId
          mode: "WX"
        .then (order) ->
          WX_API.getBrandWCPayRequestParamsAsync openId, "#{order._id}", info.cost
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
    openId = req.query.openId
    WX_API.getPayInfoAsync(openId)
    .then (info) ->
      db.place.findOneAsync
        _id: info._placeId
      .then (place) ->
        info.placeName = place.name
        info
    .then (info) ->
      info.openId = openId
      if info.status in ['idle', 'work']
        db.order.createAsync
          money: info.cost
          time: info.time
          openId: openId
          deviceStatus: info.status
          uid: info.uid
          _userId: info._userId
          _placeId: info._placeId
          mode: "WX"
        .then (order) ->
          WX_API.getBrandWCPayRequestParamsAsync openId, "#{order._id}", info.cost * 100  # 微信金额单位为分
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
    unless money and openId and _placeId
      return callback(new Error('params error'))
    money = req.query.money
    openId = req.query.openId
    _placeId = req.query._placeId
    db.order.createAsync
      money: money
      openId: openId
      _placeId: _placeId
      mode: "WX_RECHARGE"
    .then (order) ->
      WX_API.getBrandWCPayRequestParamsAsync openId, "#{order._id}", money * 100
      .then (args) ->
        rt =
          args: args
          order: order._id
        callback(null, rt)
    .catch (e) ->
      callback(e)
  @::recharge.route = ['get', '/pay/v1/recharge']

  pageView: (req, callback) ->
    openId = req.query.openId
    _placeId = req.query._placeId
    info = {}
    db.place.findOneAsync
      _id: _placeId
    .then (place) ->
      info.placeName = place.name
      info.openId = openId
      db.device.findAsync
        _placeId: _placeId
    .then (devices) ->
      info.devices = _.sortBy(_.map(devices, (device) -> device.toJSON()), (device) -> return device.name)
      db.alien.findOneAsync
        openId: openId
    .then (alien) ->
      info.user = alien.toJSON()
      info.rest = alien.money
      req.res.render('page', info)
    .catch (e) ->
      req.res.send(e.message)
  @::pageView.route = ['get', '/pay/v1/h5page']

  wxExcharge: (req, callback) ->
    {_orderId, openId} = req.query
    console.log('wx_wx query', req.query)
    unless openId and _orderId
      return callback(new Error('paramErr'))
    order = null
    alien = null
    db.alien.findOneAsync openId: openId
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
      callback(null, {state: 'ok', rest: alien.money})
    .catch (e) ->
      console.log(e)
      callback(e)
  @::wxExcharge.route = ['get', '/wx/excharge']

  confirmAndStart: (req, callback) ->
    {_orderId, uid, openId} = req.query
    console.log 'confirmAndStart', _orderId, uid, openId
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
