_ = require('lodash')
db = require('limbo').use('anmoyi')
WX_API = require('./weixin/api')
MP_API = require('./weixin/mpApi')
WXPay = require('weixin-pay')
async = require('async')
wxReply = require('./weixin/message')
redis = require('./services/redis')

class API

  """
  响应微信消息
  """
  handleMessage: (req, callback) ->
    { _message } = req
    console.log 'handleMessage', req.body
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
      info.openid = openid
      if info.status in ['idle', 'work']
        db.order.createAsync
          money: info.cost
          time: info.time
          openId: openid
          deviceStatus: info.status
          uid: info.uid
        .then (order) ->
          console.log "payTestView:getBrandWCPayRequestParamsAsync", openid, "#{order._id}", info.cost
          WX_API.getBrandWCPayRequestParamsAsync openid, "#{order._id}", info.cost
          .then (args) ->
            info.payargs = args
            info.order = "#{order._id}"
            console.log 'payTestView:info', info
            req.res.render('pay', info)
      else
        info.payargs = {}
        req.res.render('pay', info)
    .catch ->
      req.res.send('system error, please try later')
  @::payTestView.route = ['get', '/view/test/h5pay']

  orderStatus: (req, callback) ->
    order = req.query.order
    expect = req.query.expect
    console.log 'orderStatus in', order, expect
    unless order
      return callback(new Error('order is required'))
    db.order.findOneAsync
      _id: order
    .then (order) ->
      console.log 'orderStatus:order', order
      if expect and order.status isnt expect
        WX_API.queryOrderAsync out_trade_no: "#{order._id}"
        .then (wx_order) ->
          console.log 'orderStatus:wxOrder', wx_order
          if wx_order.trade_state isnt order.status
            order.status = wx_order.trade_state
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
