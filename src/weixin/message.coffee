weixinAPI = require('./api')
# qrcode = require('./qrcode')
redis = require('../services/redis')
db = require('limbo').use('anmoyi')
qs = require('qs')
config = require('config')
sockSrv = require('../services/socket')

subscribe = (message, words) ->

  weixinAPI.sendMessage(message.fromusername, words or """
    感谢您关注 轻松驿客 ！
  """)

sendPayTmp = (uid, fromusername) ->
  db.device.findOne
    uid: uid
  , (err, device) ->
    if err or not device
      subscribe("设备未找到，请联系管理员")
    else
      redis.setex "PAYINFO.#{fromusername}", 24*60*60, device.uid, ->
      info = device.getPayInfo()
      weixinAPI.sendTemplateMessage(
        touser: fromusername
        template_id: config.MP_WEIXIN.templateIDs.pay
        url: "#{config.host}/#{config.h5.pay}?openid=#{fromusername}"
        topcolor: "#ff0000"
        data:
          first:
            value: "点击该链接付款"
          keyword1:
            value: "#{device.name || '1号'} 按摩椅"
          keyword2:
            value: "#{info.cost} 元" or "5元"
          remark:
            value: "请确认该按摩椅空闲"
      )

module.exports = (message) ->
  type = message.msgtype
  event = message.event
  eventkey = message.eventkey
  fromusername = message.fromusername
  console.log type, event, eventkey
  if type is 'event'
    if event is 'subscribe'
      subscribe(message)
      if /^qrscene/.test(eventkey)
        [action, uid] = eventkey.split('_')
        sendPayTmp(uid, fromusername)
    else if event is 'SCAN'
      uid = eventkey
      if uid
        sendPayTmp(uid, fromusername)
    else if event is 'unsubscribe'
      console.log 'unsubscribe'
  else if type is 'text'
    subscribe(message)
  else if type is 'click'
    if eventkey is 'pay'
      redis.getAsync "PAYINFO.#{fromusername}"
      .then (uid) ->
        if not uid
          return subscribe(message, "系统未检测到您扫描过任何设备，请先扫描一台设备二维码进行支付。")
        sendPayTmp(uid, fromusername)
      .catch (e) ->
        subscribe(message, "系统异常，请稍后再试！")
    else if /^set/.test(eventkey)
      code = eventkey.split('_')[1]
      redis.getAsync "PAYINFO.#{fromusername}"
      .then (uid) ->
        if not uid
          return subscribe(message, "系统未检测到您使用的设备。请先支付使用按摩椅，再使用该功能！如已支付，请联系客服。")
        db.device.findOneAsync
          uid: uid
      .then (device) ->
        unless device.status is 'work'
          return subscribe(message, "您的服务时间已结束，如需继续使用，可以点击'支付续费'快捷续费！")
        sockSrv.set(device.uid, code, (err) ->
          if err
            subscribe(message, "操作失败，请稍后再试!")
          else
            subscribe(message, "操作成功!")
        )
      .catch (e) ->
        subscribe(message, "系统异常，请稍后再试！")



