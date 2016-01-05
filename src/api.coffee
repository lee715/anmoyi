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
    {openid} = req.query
    console.log 'unifiedorder',openid
    productid = u.v1()
    WX_API.getBrandWCPayRequestParams(openid, (err, rt) ->
      console.log err, rt
      callback(err, rt)
    )
  @::unifiedorder.route = ['get', '/wx/unifiedorder']

  getUserInfoCode: (req, callback) ->
    {body, query} = req
    code = query.code
    console.log 'getUserInfoCode:code', code
    return callback('unbindError') unless code
    async.waterfall [
      (next) ->
        MP_API.getUserInfoToken code, (err, token, openid) ->
          console.log 'getUserInfoCode:token', err, token, openid
          next(null, token, openid)
      (token, openid, next) ->
        MP_API.getUserInfo token, openid, next
      (user, next) ->
        console.log 'getUserInfoCode:user', user
        next()
    ], (err) ->
      if err
        console.log err
      req.redirect = config.LONG_TICKET.url
      callback()

  @::getUserInfoCode.route = ['get', '/code']

  getAuthUrl: (req, callback) ->
    callback(null, WX_API.getViewUrl({scope: "snsapi_userinfo"}))
  @::getAuthUrl.route = ['get', '/auth']

  getTicketUrl: (req, callback) ->
    { uid } = req.query
    MP_API.getQrcodeTicket(uid, (err, ticket) ->
      callback(err, ticket.url)
    )
  @::getTicketUrl.route = ['get', '/ticket']

  orderDevice: (req, callback) ->
    { uid, _orderId, action, openid } = req.query
    console.log 'orderDevice in', uid, _orderId, action, openid
    unless uid and openid and _orderId
      return callback(new Error('paramErr'))
    redis.getAsync "ORDER.COMMAND.LOCK.#{_orderId}"
    .then (lock) ->
      console.log 'lock', lock
      throw new Error('order is handling') if lock
      redis.setexAsync "ORDER.COMMAND.LOCK.#{_orderId}", 60*10, 1
    .then ->
      db.order.findOneAsync
        _id: _orderId
        openId: openid
        uid: uid
      .then (order) ->
        console.log 'orderDevice:order', order
        unless order
          throw new Error('orderNotFound')
        if order.status is 'SUCCESS'
          if action is "start"
            sockSrv.startAsync(uid, order.time)
            .then ->
              order.serviceStatus = 'STARTED'
              order.saveAsync()
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
      console.log e
      callback(e)
  @::orderDevice.route = ['get', '/command']

module.exports = new API