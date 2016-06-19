_         = require('lodash')
qs        = require('qs')
config    = require('config')
async     = require('async')
uuid      = require('uuid')
crypto    = require('crypto')
request   = require('request')
urlType   = require('./url')
redis     = require('../services/redis')
Promise   = require('bluebird')

module.exports = MP_API =

  refreshTicket: (callback = ->) ->
    self = @
    expires = []
    async.waterfall [
      (next) ->
        self._getMPToken next
      (res, next) ->
        { access_token, expires_in } = res
        expires.push expires_in
        self._getTicket access_token, next
    ], (err, res) ->
      return callback err if err
      { expires_in } = res
      expires.push expires_in
      callback null, Math.min.apply(Math, expires)

  getTicket: (url, callback) ->
    if typeof url is 'function'
      callback = url
      url = null

    redis.get config.MP_WEIXIN.ticketKey, (err, ticket) ->
      return callback('redisError') if err
      return callback('ticketNotFound') unless ticket

      noncestr = uuid.v4().split('-').join('')
      timestamp = Math.floor(Date.now()/1000)
      signature_list = [
        "jsapi_ticket=#{ticket}"
        "noncestr=#{noncestr}"
        "timestamp=#{timestamp}"
        "url=#{url or config.MP_WEIXIN.JSSDK_URL}"
      ]

      ret =
        noncestr: noncestr
        timestamp: timestamp
        signature: crypto.createHash('sha1').update(signature_list.join('&')).digest('hex')
      callback null, ret

  getQrcodeTicket: (scenes, callback) ->
    self = @
    async.waterfall [
      (next) ->
        self.getMPToken next
      (access_token, next) ->
        request.post
          headers:
            'content-type': 'application/json'
          url: urlType.qrcodeURL("access_token=#{access_token}")
          timeout: 5000
          body: JSON.stringify({
            action_name: 'QR_LIMIT_STR_SCENE'
            action_info:{
              scene: {
                scene_str: scenes
              }
            }
          })
        , (err, res, body) ->
          console.log(err) if err
          next(err, JSON.parse(body))
    ], callback

  getUserInfoToken: (code, callback) ->
    fields = ['appid', 'secret']
    params = _.pick(config.MP_WEIXIN, fields)
    params.code = code
    params.grant_type = 'authorization_code'
    query = qs.stringify(params)

    request.get
      url: urlType.getWXTokenURL(query)
      timeout: 5000
      json: true
    , (err, resp, body) ->
      if err
        console.log(err)
        return callback('wxAPIError')

      {access_token, expires_in, openId} = body
      callback(err, access_token, openId)

  getUserInfo: (token, openId, callback) ->
    fields = {
      'access_token': token
      'openid': openId
    }
    query = qs.stringify(fields)
    request.get
      url: urlType.userInfoURL(query)
      timeout: 5000
      json: true
    , (err, resp, body) ->
      return callback('wxAPIError') if err or body?.errcode

      {openId, nickname, unionid} = body
      if unionid
        userid = unionid
      else
        userid = openId
      callback err, body

  getMPToken: (callback) ->
    redis.get config.MP_WEIXIN.tokenKey, callback

  _getMPToken: (callback) ->
    fields = ['appid', 'secret', 'grant_type']
    query = qs.stringify(_.pick(config.MP_WEIXIN, fields))

    request.get
      url: urlType.getMPTokenURL(query)
      timeout: 5000
      json: true
    , (err, resp, body) ->
      console.log(err) if err
      return callback('wxAPIError') if err or body?.errcode

      {access_token, expires_in} = body
      redis.set config.MP_WEIXIN.tokenKey, access_token
      redis.expire config.MP_WEIXIN.tokenKey, expires_in
      callback null, body

  _getTicket: (access_token, callback) ->
    query = qs.stringify
      access_token: access_token
      type: 'jsapi'

    request.get
      url: urlType.ticketURL(query)
      timeout: 5000
      json: true
    , (err, resp, body) ->
      console.log(err) if err
      return callback('wxAPIError') if err or body?.errcode

      {ticket, expires_in} = body

      redis.set config.MP_WEIXIN.ticketKey, ticket
      redis.expire config.MP_WEIXIN.ticketKey, expires_in
      callback null, body

  setupMpTicket: (callback) ->
    self = @
    doRefresh = ->
      self.refreshTicket (err, expires) ->
        return callback(err) if err
        setTimeout doRefresh, expires * 1000 - 5000
    doRefresh()
Promise.promisifyAll(MP_API)
