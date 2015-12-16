
config = require 'config'


getHost = (useProduction = false) ->
  host = "https://account.teambition.com"
  if config.DEBUG and not useProduction
    host = "http://account.project.ci"
  host

setCookieURI = '/weixin/setcookie'

module.exports =

  tplURL: (next) ->
    config.MP_WEIXIN.successURL + config.PREFIX + '/tpl/message?next=' + encodeURIComponent(next)

  indexURL: (useProduction = false) ->
    getHost(useProduction) + config.PREFIX

  loginURL: (useProduction = false, isMP = false) ->
    if isMP
      config.MP_WEIXIN.successURL + '/#/wx_login'
    else getHost(useProduction) + config.PREFIX + '/login'

  successURL: (isMP = false, useProduction = false, setcookie = false) ->
    if isMP
      return @mpSuccessURL(useProduction, setcookie)
    if setcookie
      getHost(useProduction) + setCookieURI + '?state=' + config.WX_OPEN_PLATFORM.state
    else config.WX_OPEN_PLATFORM.successURL

  mpSuccessURL: (useProduction = false, setcookie = false) ->
    if setcookie
      getHost(useProduction) + setCookieURI + '?state=' + config.MP_WEIXIN.state
    else config.MP_WEIXIN.successURL

  redirectURL: ->
    getHost(true) + config.PREFIX + config.WX_OPEN_PLATFORM.redirectURI

  authURL: (qs) ->
    config.WX_OPEN_PLATFORM.authURL + "?" + qs + '#' + config.WX_OPEN_PLATFORM.wechat_redirect

  bindErrorURL: ->
    config.WX_OPEN_PLATFORM.bindErrorURL

  getWXTokenURL: (qs) ->
    config.WX_OPEN_PLATFORM.tokenURL + "?" + qs

  getMPTokenURL: (qs) ->
    config.MP_WEIXIN.tokenURL + "?" + qs

  userInfoURL: (qs, isMP = false) ->
    return @openIdURL(qs) if isMP
    config.WX_OPEN_PLATFORM.userInfoURL + "?" + qs

  ticketURL: (qs) ->
    config.MP_WEIXIN.ticketURL + "?" + qs

  getSetCookieURI: ->
    setCookieURI

  menuURL: "https://api.weixin.qq.com/cgi-bin/menu/create"

  openIdURL: (qs) ->
    config.MP_WEIXIN.userInfoURL + "?" + qs

  messageURL: (qs) ->
    config.MP_WEIXIN.msgURL + "?" + qs

  qrcodeURL: (qs) ->
    config.MP_WEIXIN.qrcodeURL + "?" + qs

  getMPAuthURL: (qs) ->
    config.MP_WEIXIN.authURL + "?" + qs

  getSendTemplateMsgURL: (qs) ->
    config.MP_WEIXIN.templateURL + '?' + qs
