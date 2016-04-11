weixinAPI = require('./api')
MP_API = require('./mpApi')
# qrcode = require('./qrcode')
redis = require('../services/redis')
db = require('limbo').use('anmoyi')
qs = require('qs')
config = require('config')
sockSrv = require('../services/socket')
moment = require('moment')
_ = require('lodash')

subscribe = (message, words) ->

  weixinAPI.sendMessage(message.fromusername, words or """
    感谢使用"轻松驿客"。

    在使用过程中遇到任何疑问请在公众号内留言或致电4009986682.
    我们会竭诚为您服务。

    轻松驿客祝您生活愉快~
  """)

sendPayTmp = (uid, fromusername) ->
  db.device.findOne
    uid: uid
  , (err, device) ->
    if err or not device
      subscribe("设备未找到，请联系管理员")
    else
      redis.setex "PAYINFO.#{fromusername}", 60*60, device.uid, ->
      info = device.getPayInfo()
      weixinAPI.sendTemplateMessage(
        touser: fromusername
        template_id: config.MP_WEIXIN.templateIDs.pay
        url: "#{config.host}#{config.h5.pay}?openId=#{fromusername}"
        topcolor: "#ff0000"
        data:
          first:
            value: "请点击这里进入微信安全支付"
          keyword1:
            value: "#{device.name || '1号'}"
          keyword2:
            value: "#{info.cost} 元" or "5元"
          remark:
            value: "支付完成后请点击下方的“启动”按钮"
      )

sendPayTmp2 = (_placeId, fromusername) ->
  db.place.findOne
    _id: _placeId
  , (err, place) ->
    if err or not place
      return subscribe("场地未找到，请联系管理员")

    weixinAPI.sendTemplateMessage(
      touser: fromusername
      template_id: config.MP_WEIXIN.templateIDs.pay
      url: "#{config.host}#{config.h5.page}?openId=#{fromusername}&_placeId=#{_placeId}"
      topcolor: "#ff0000"
      data:
        first:
          value: "请点击这里进入支付操作界面"
        keyword1:
          value: "#{place.name}"
        keyword2:
          value: "请根据提示选择"
        remark:
          value: ""
    )

module.exports = (message) ->
  type = message.msgtype
  event = message.event
  eventkey = message.eventkey
  console.log type, event, eventkey
  fromusername = message.fromusername
  weixinAPI.getUserInfo fromusername, (err, user) ->
    db.alien.findOneAsync
      openId: fromusername
    .then (alien) ->
      unless alien
        db.alien.createAsync
          openId: fromusername
          name: user.nickname
          city: user.city
          province: user.province
          country: user.country
      else
        alien.openId = fromusername
        alien.name = user.nickname
        alien.city = user.city
        alien.province = user.province
        alien.country = user.country
        alien.saveAsync()
    .catch (e) ->
      console.log 'alien', e
  if type is 'event'
    if event is 'subscribe'
      subscribe(message)
      if /^qrscene/.test(eventkey)
        [action, uid] = eventkey.split('_')
        sendPayTmp(uid, fromusername)
    else if event is 'SCAN'
      uid = eventkey
      if uid.length is 12
        sendPayTmp(uid, fromusername)
      else if uid.length is 24
        sendPayTmp2(uid, fromusername)
    else if event is 'unsubscribe'
      console.log 'unsubscribe'
    else if event is 'CLICK'
      if eventkey is 'how_to_use'
        subscribe(message, """
          您好！
          1、扫描(请用微信扫描二维码，并关注公众号)；
          2、支付(点击弹出的链接对话框进入支付页面)；
          3、点击“完成”(成功支付后，点击“完成”以启动按摩椅)

          请注意：
          二维码仅对所在的那台设备有效，如您更换了座位，请重新扫描。
          如需续费，请重新扫描并支付即可。

          任何疑问请致电4009986682，谢谢！
        """
        )
      else if eventkey is 'notice'
        subscribe(message, """
          ★★以下情形及人士禁止使用本机★★
          ◎儿童、孕妇及高龄人士
          ◎处于经期的女士
          ◎酒后或饮食过饱时
          ◎当您身体有任何疾病时
          ◎体重超过120千克之人士
          ◎安装有植入式医疗器械之人士
          ◎当您发现本机面料|电源线|控制面板
            有任何损坏时，禁止使用。

          ★★发生以下情形请立即停止使用★★
          ◎使用过程中如您感到任何不适，请立即停止使用！
          ◎本机仅供单人使用，严禁2人或多人同时使用！
          ◎严禁坐在按摩椅扶手上！以免发生意外！

          ★★温馨提示★★
          ◎本机为投币式全自动按摩椅
          ◎使用前请务必阅读注意事项
          ◎足额投币后按摩椅自动运行
          ◎贴近靠背乘坐以获得最佳体验
          ◎请妥善保管好您的随身物品
          ◎禁止在按摩椅上吸烟
          ◎使用按摩椅时请勿饮食
        """)
      else if eventkey is 'more_info'
        subscribe(message, """
          您好，如有任何疑问或者建议，请致电4009986682，或留言，我们会及时回复您的信息，谢谢！
        """)
      else if eventkey is 'start'
        today = moment().startOf('day').toDate()
        total = {}
        db.order.findAsync
          openId: fromusername
          created:
            $gt: today
          status: 'SUCCESS'
          serviceStatus:
            $ne: 'STARTED'
        .then (orders) ->
          total.unstarted = orders.length
          orders
        .map (order) ->
          sockSrv.startAsync(order.uid, order.time)
          .then (state) ->
            if state
              order.serviceStatus = 'STARTED'
              order.saveAsync()
              .then ->
                db.device.updateAsync
                  uid: order.uid
                , status: 'work'
                ,
                  upsert: false
                  new: false
        .then ->
          db.order.findAsync
            openId: fromusername
            created:
              $gt: today
            status: 'PREPAY'
        .map (order) ->
          weixinAPI.queryOrderAsync out_trade_no: "#{order._id}"
          .then (wx_order) ->
            if wx_order.trade_state is 'SUCCESS'
              order.status = "SUCCESS"
              sockSrv.startAsync(order.uid, order.time)
              .then (state) ->
                if state
                  order.serviceStatus = 'STARTED'
                  order.saveAsync()
                  .then ->
                    db.device.updateAsync
                      uid: order.uid
                    , status: 'work'
                    ,
                      upsert: false
                      new: false
              .then ->
                wx_order.trade_state
            else
              ''
        .then (rt) ->
          total.prepay = rt.length
          rt = _.compact(rt)
          total.unpayed = rt.length
          if total.unstarted or total.unpayed
            msg = """
            找到 #{total.unstarted} 条已付款未启动的设备，正在为您自动启动
            找到 #{total.unpayed} 条未确认状态的订单，已成功标记订单状态，并自动启动设备
            如仍有问题，请致电4009986682，谢谢！
            """
            subscribe(message, msg)
          else
            redis.getAsync "PAYINFO.#{fromusername}"
            .then (payinfo) ->
              if payinfo
                msg = """
                您好！请点击上面的链接，成功支付后，点击“完成”，按摩椅会自行启动。
                如果按摩椅没有自行启动，请点击“启动”按钮。
                其他问题，请致电4009986682，谢谢！
                """
              else
                msg = """
                您好！
                请扫描您所乘坐的按摩椅上的二维码，成功支付后，点击“完成”，按摩椅会自行启动。
                如果按摩椅没有自行启动，请点击“启动”按钮。
                其他问题，请致电4009986682，谢谢！
                """
              subscribe(message, msg)
        .catch (e) ->
          console.log e.stack
  else if type is 'text'
    subscribe(message)
  # else if type is 'click'
    # if eventkey is 'pay'
    #   redis.getAsync "PAYINFO.#{fromusername}"
    #   .then (uid) ->
    #     if not uid
    #       return subscribe(message, "系统未检测到您扫描过任何设备，请先扫描一台设备二维码进行支付。")
    #     sendPayTmp(uid, fromusername)
    #   .catch (e) ->
    #     subscribe(message, "系统异常，请稍后再试！")
    # else if /^set/.test(eventkey)
    #   code = eventkey.split('_')[1]
    #   redis.getAsync "PAYINFO.#{fromusername}"
    #   .then (uid) ->
    #     if not uid
    #       return subscribe(message, "系统未检测到您使用的设备。请先支付使用按摩椅，再使用该功能！如已支付，请联系客服。")
    #     db.device.findOneAsync
    #       uid: uid
    #   .then (device) ->
    #     unless device.realStatus is 'work'
    #       return subscribe(message, "您的服务时间已结束，如需继续使用，可以点击'支付续费'快捷续费！")
    #     sockSrv.set(device.uid, code, (err) ->
    #       if err
    #         subscribe(message, "操作失败，请稍后再试!")
    #       else
    #         subscribe(message, "操作成功!")
    #     )
    #   .catch (e) ->
    #     subscribe(message, "系统异常，请稍后再试！")



