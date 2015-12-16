config = require('config')
_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('./services/util')
WX_API = require('./weixin/api')
MP_API = require('./weixin/mpApi')
async = require('async')
wxReply = require('./weixin/message')
sockSrv = require('./services/socket')

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
    db.order.findOneAsync
      _id: _orderId
      openId: openid
      uid: uid
    .then (order) ->
      console.log 'orderDevice:order', order
      unless order
        return callback(new Error('orderNotFound'))
      if action is "start"
        sockSrv.start(uid, order.time, (err, rt) ->
          console.log 'orderDevice:start', err, rt
        )
      else if action in ['1F', '20', '1E', '21', '22', '24']
        sockSrv.set(uid, action, (err, rt) ->
          console.log 'orderDevice:set', err, rt
          callback(null, "ok")
        )
      else
        callback(new Error('unknownAction'))
  @::orderDevice.route = ['get', '/command']

module.exports = new API
