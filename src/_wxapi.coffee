{ mch_id, appid, body, detail, total_fee, key } = require('config').wxConfig
{ ip, host } = require('config')
fs = require('fs')
u = require('./services/util')
request = require('request')
WXPay = require('weixin-pay')

wxpay = WXPay
  appid: appid
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

module.exports =

  generateQrUrl: (extra) ->
    return wxpay.createMerchantPrepayUrl product_id: '123456'
    # url = 'weixin://wxpay/bizpayurl'
    # data =
    #   appid: appid
    #   mch_id: mch_id
    #   time_stamp: parseInt((new Date).getTime()/1000)
    #   product_id: u.v1()
    #   nonce_str: u.v4()
    # data.sign = generateWxSign(data)
    # return "#{url}?#{u.qsParseSortByAscii(data)}"

  # 退款
  refund: (order, money, callback) ->
    param =
      appid: appid
      mch_id: mch_id
      op_user_id: mch_id
      out_refund_no: u.v4()
      total_fee: money
      refund_fee: money
      out_trade_no: order
    wxpay.refund param, callback

  # 统一下单api
  unifiedorder: (product_id, open_id, callback) ->
    url = 'https://api.mch.weixin.qq.com/pay/unifiedorder'
    data =
      appid: appid
      mch_id: mch_id
      device_info: 'WEB'
      nonce_str: u.v4()
      body: body
      detail: detail
      out_trade_no: product_id
      total_fee: total_fee
      spbill_create_ip: ip
      time_start: wx_date()
      notify_url: "#{host}/wx/notify"
      trade_type: "NATIVE"
      product_id: product_id
      openId: openId
    data.sign = generateWxSign(data)
    query = u.qsParseSortByAscii(data)
    request.post
      url: url
      data: data
      json: true
    , (err, res, body) ->
      callback(err, body)
