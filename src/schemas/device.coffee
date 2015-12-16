
module.exports = (Schema) ->
  deviceSchema = new Schema
    # 代理商
    _userId:
      type: Schema.Types.ObjectId
    uid: String
    name: String
    lastUsed:
      type: Date
      default: Date.now
    # 场所位置
    _placeId: Schema.Types.ObjectId
    # 设备状态
    status:
      type: String
      default: 'stop'
    # 价格
    price:
      type: Number
      default: 5
    time:
      type: Number
      default: 10
    # 折扣
    discount:
      type: Number
      default: 100
    # 减免
    remission:
      type: Number
      default: 0
    # 累计收入
    income:
      type: Number
      default: 0
    wxTime:
      type: Number
      default: 0
    # 投入使用日期
    created:
      type: Date
      default: Date.now
    updated:
      type: Date
      default: Date.now
  ,
    read: 'secondaryPreferred'
    toObject:
      virtuals: true
      getters: true
    toJSON:
      virtuals: true
      getters: true

  deviceSchema.virtual 'cost'
    .get ->
      return @price*@discount/100 - @remission

  deviceSchema.methods.getPayInfo = ->
    info =
      name: @name
      place: @place
      cost: @cost
      status: @status
      # time: @time
      time: 3
      uid: @uid
    return info
  deviceSchema

