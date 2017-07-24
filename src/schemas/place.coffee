
module.exports = (Schema) ->
  Place = new Schema
    name: String
    province: String
    city: String
    district: String
    company: String
    email: String
    mailAddress: String
    qq: String
    bankName: String
    bankAccount: String
    # 客服人员id
    _salesmanId: Schema.Types.ObjectId
    # 客服人员分成模式
    salesmanMode:
      type: String
      default: 'percent'
    # 客服人员分成数额
    salesmanCount: Number
    # 代理商id
    _agentId: Schema.Types.ObjectId
    agentMode:
      type: String
      default: 'percent'
    agentCount: Number
    contacts:
      type: Schema.Types.Mixed
      default: []
    password:
      type: String
      default: ->
        parseInt(Math.random()*1000000-1)
    role:
      type: String
      default: "place"
    p:
      type: Number
      default: 100
    # 价格
    price:
      type: String
      default: 5
    time:
      type: String
      default: 10
    mode:
      type: String
      default: 'airport'
    created:
      type: Date
      default: Date.now
    updated:
      type: Date
      default: Date.now

  Place.virtual 'location'
    .get ->
      return "#{@province}-#{@city}-#{@district}"

  Place.methods.format = ->
    data = @toJSON()
    delete data.password
    return data
  Place
