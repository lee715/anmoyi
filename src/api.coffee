config = require('config')
_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('./services/util')
WX_API = require('./weixin/api')
MP_API = require('./weixin/mpApi')
async = require('async')
wxReply = require('./weixin/message')
sockSrv = require('./services/socket')
redis = require('./services/redis')

pluck = (keys) ->
  (arr) ->
    rt = []
    arr.forEach (item) ->
      rt.push _.pick item, keys
    return rt

deviceJson = ['_id', 'lastUsed', 'uid', '_userId', 'created', 'updated', 'place', 'location', 'price', 'status', 'discount', 'remission', 'income']

formatUser = (user) ->
  return _.pick(user, ['_id', 'role', 'email', 'name', 'company', 'phone', 'location'])

class API

  unifiedorder: (req, callback) ->
    {openId} = req.query
    productid = u.v1()
    WX_API.getBrandWCPayRequestParams(openId, (err, rt) ->
      callback(err, rt)
    )
  @::unifiedorder.route = ['get', '/wx/unifiedorder']

  getUserInfoCode: (req, callback) ->
    {body, query} = req
    code = query.code
    return callback('unbindError') unless code
    async.waterfall [
      (next) ->
        MP_API.getUserInfoToken code, (err, token, openId) ->
          next(null, token, openId)
      (token, openId, next) ->
        MP_API.getUserInfo token, openId, next
      (user, next) ->
        next()
    ], (err) ->
      req.redirect = config.LONG_TICKET.url
      callback()

  @::getUserInfoCode.route = ['get', '/code']

  getAuthUrl: (req, callback) ->
    callback(null, WX_API.getViewUrl({scope: "snsapi_userinfo"}))
  @::getAuthUrl.route = ['get', '/auth']

  getTicketUrl: (req, callback) ->
    { uid, _placeId } = req.query
    MP_API.getQrcodeTicket(uid or _placeId, (err, ticket) ->
      callback(err, ticket.url)
    )
  @::getTicketUrl.route = ['get', '/ticket']

  payAjax: (req, callback) ->
    {openId, _deviceId, count} = req.query
    console.log('payAjax', req.query)
    unless openId and _deviceId and count
      return callback(new Error('params error'))
    db.alien.findOneAsync openId: openId
    .then (alien) ->
      unless alien.money
        throw new Error('need more money')
      db.device.findOneAsync _id: _deviceId
      .then (device) ->
        price = device.price * count
        time = device.time * count
        if device.realStatus is 'fault'
          throw new Error('device is fault')
        if alien.money < price
          throw new Error('need more money')
        sockSrv.startAsync(device.uid, time)
        .then (state) ->
          throw new Error('start failed') unless state
          alien.money = alien.money - price
          alien.saveAsync()
        .then ->
          db.order.createAsync
            openId: openId
            uid: device.uid
            time: time
            money: price
            status: "SUCCESS"
            serviceStatus: "STARTED"
            mode: "API"
            _userId: device._userId
            _placeId: device._placeId
        .then ->
          rt =
            state: 'ok'
            rest: alien.money
          callback(null, rt)
    .catch (e) ->
      console.log e
      callback(e)
  @::payAjax.route = ['get', '/payAjax']

  prepay: (req, callback) ->
    {money, openId} = req.query
    unless money and openId
      return callback(new Error('params error'))
    db.order.createAsync
      money: money
      openId: openId
      mode: "WX_EXCHARGE"
    .then (order) ->
      WX_API.getBrandWCPayRequestParamsAsync openId, "#{order._id}", money*100  # 微信金额单位为分
      .then (args) ->
        callback(null, {args: args, order: order._id})
  @::prepay.route = ['get', '/prepay']

  orderDevice: (req, callback) ->
    { uid, _orderId, action, openId } = req.query
    unless uid and openId and _orderId
      return callback(new Error('paramErr'))
    redis.getAsync "ORDER.COMMAND.LOCK.#{_orderId}"
    .then (lock) ->
      throw new Error('order is handling') if lock
      redis.setexAsync "ORDER.COMMAND.LOCK.#{_orderId}", 60*10, 1
    .then ->
      db.order.findOneAsync
        _id: _orderId
        openId: openId
        uid: uid
      .then (order) ->
        unless order
          throw new Error('orderNotFound')
        if order.status is 'SUCCESS'
          if action is "start"
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
          else if action in ['1F', '20', '1E', '21', '22', '24']
            sockSrv.setAsync(uid, action)
            .then ->
              callback(null, 'ok')
          else
            throw new Error('unknownAction')
        else
          throw new Error('unvalidOrder')
    .then ->
      redis.del "ORDER.COMMAND.LOCK.#{_orderId}"
    .catch (e) ->
      callback(e)
  @::orderDevice.route = ['get', '/command']

module.exports = new API
