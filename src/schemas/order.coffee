
module.exports = (Schema) ->
  new Schema
    money: String
    time: String
    status:
      type: String
      default: "PREPAY"
    # WX or TB
    mode:
      type: String
      default: "TB"
    # 用户wx openid
    openId: String
    # 设备uid
    uid: String
    _userId: Schema.Types.ObjectId
    deviceStatus: String
    serviceStatus:
      type: String
      default: "BEFORE"
    created:
      type: Date
      default: Date.now
    updated:
      type: Date
      default: Date.now
