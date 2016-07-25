_       = require('lodash')
qs      = require('qs')
config  = require('config')
async   = require('async')
request = require('request')
urlType = require('./url')
redis   = require('../services/redis')
mpAPI   = require('./mpApi')
db = require('limbo').use('anmoyi')
Promise = require('bluebird')
{ mch_id, body, detail, total_fee, key } = require('config').wxConfig
{ ip, host } = require('config')
u = require('../services/util')
request = require('request')
WXPay = require('weixin-pay')
wxpay = WXPay
  appid: config.MP_WEIXIN.appid
  mch_id: mch_id
  partner_key: key

wx_date = (date) ->
  if date
    date = new Date(date)
  else
    date = new Date
  str = date.toJSON()
  return str.replace(/-|T|:|.\d{3}Z/g, '')

generateWxSign = (data) ->
  qsStr = u.qsParseSortByAscii(data)
  qsStr += "&key=#{key}"
  return u.md5(qsStr).toUpperCase()

module.exports = WX_API =
  getAccessToken: -> (req, res, next) ->
    return next('codeNotFound') unless req.query.code

    fields = ['appid', 'secret', 'grant_type']
    query = _.pick(config.WX_OPEN_PLATFORM, fields)
    query.code = req.query.code

    if req.isMP
      _.assign(query, _.pick(config.MP_WEIXIN, ['appid', 'secret']))

    query = qs.stringify(query)
    request.get
      url: urlType.getWXTokenURL(query)
      timeout: 5000
      json: true
    , (err, resp, body) ->
      return next('unbindError') if body?.errcode is 40029
      return next('wxAPIError') if err or body?.errcode
      req.weixin_auth = body: body
      next()

  getUserInfo: ({access_token, openId, isMP}, callback) ->
    self = @

    async.waterfall [
      (next) ->
        if isMP
          mpAPI.getMPToken next
        else
          next()
    ], (err, token) ->
      return callback(err) if err
      query = qs.stringify
        access_token: token or access_token
        openid: openId

      request.get
        url: urlType.userInfoURL(query, isMP)
        timeout: 5000
        json: true
      , (err, resp, body) ->
        return callback('wxAPIError') if err or body?.errcode
        return callback null, body

  sendMessage: (touser, content) ->
    @_getAccessToken (err, access_token) ->
      return if err
      request.post
        headers:
          'content-type': 'application/json'
        url: urlType.messageURL("access_token=#{access_token}")
        timeout: 5000
        body: JSON.stringify({
          touser: touser
          text: content: content
          msgtype: 'text'
        })
      , (err, resp, body) ->
        console.log(err) if err

  sendTemplateMessage: (content) ->
    console.log('sendTemplateMessage', content)
    mpAPI.getMPToken (err, access_token) ->
      return if err
      request.post
        headers:
          'content-type': 'application/json'
        url: urlType.getSendTemplateMsgURL("access_token=#{access_token}")
        timeout: 5000
        body: JSON.stringify(content)
      , (err, res, body) ->
        console.log(err, body)

  getUserInfo: (openId, callback) ->
    self = @

    async.waterfall [
      (next) ->
        self._getAccessToken next
      (access_token, next) ->
        query = qs.stringify
          access_token: access_token
          openid: openId

        request.get
          url: urlType.openIdURL(query)
          timeout: 5000
          json: true
        , (err, resp, body) ->
          return next('wxAPIError') if err or body?.errcode
          return next null, body
    ], callback

  _getAccessToken: (callback) ->
    redis.get config.MP_WEIXIN.tokenKey, (err, resp) ->
      return callback('redisError') if err
      return callback null, resp

  checkSingle: (message, callback) ->
    _id = message.msgid

    unless _id
      _id = "#{message.fromusername}:#{message.createtime}"

    rkey = "WEIXIN:SINGLE:ID:#{_id}"

    async.waterfall [
      (next) ->
        redis.get rkey, (err, resp) ->
          return next('redisError') if err
          return next('messageExist') if resp
          return next()
      (next) ->
        redis.set rkey, JSON.stringify(message), (err) ->
          return next('redisError') if err
          return next()
    ], callback

  getViewUrl: (options = {}) ->
    _scope = options.scope or 'snsapi_base'
    projectViews = qs.stringify({
      appid: config.MP_WEIXIN.appid
      redirect_uri: config.MP_WEIXIN.codeURL
      response_type: 'code'
      scope: _scope
      state: options.state or config.MP_WEIXIN.state
    })
    urlType.getMPAuthURL(projectViews) + "#wechat_redirect"

  createMenu: ->
    self = @

    buttons = config.WX_OPEN_PLATFORM.buttons

    async.waterfall [
      (next) ->
        self._getAccessToken next
      (access_token, next) ->
        query = qs.stringify
          access_token: access_token

        url = "#{urlType.menuURL}?#{query}"

        request
          url: url
          timeout: 5000
          method: 'POST'
          body: buttons
          json: true
        , (err, resp, body) ->
          return next('wxAPIError') if err or body?.errcode
          return next null, body
    ], (err, body) ->
      console.log(err) if err

  unifiedorder: (product_id, open_id, callback) ->
    wxpay.createUnifiedOrder
      device_info: 'WEB'
      nonce_str: u.v4()
      body: body
      detail: detail or ''
      out_trade_no: product_id
      total_fee: total_fee
      spbill_create_ip: ip
      time_start: wx_date()
      notify_url: "#{host}/wx/notify"
      trade_type: "NATIVE"
      product_id: product_id
      openid: open_id
    , (err, res) ->
      callback(err, res)

  getBrandWCPayRequestParams: (open_id, order, cost, callback) ->
    wxpay.getBrandWCPayRequestParams
      body: body
      detail: detail or ''
      out_trade_no: order
      total_fee: cost
      spbill_create_ip: ip
      notify_url: "#{host}/wx/notify"
      openid: open_id
    , (err, res) ->
      callback(err, res)

  h5pay: (prepay_id) ->
    data =
      appId: appid
      timeStamp: wx_date()
      nonceStr: u.v4()
      package: prepay_id
      signType: "MD5"
    data.paySign = generateWxSign(data)
    return u.qsParseSortByAscii(data)

  getPayInfo: (openId, callback) ->
    redis.getAsync "PAYINFO.#{openId}"
    .then (uid) ->
      db.device.findOneAsync uid: uid
    .then (device) ->
      info = device.getPayInfo()
      callback(null, info)
    .catch callback

  useWXCallback: wxpay.useWXCallback

  queryOrder: ->
    wxpay.queryOrder.apply(wxpay, arguments)

Promise.promisifyAll(WX_API)


