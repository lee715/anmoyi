
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
    # 代理商id
    _agentId: Schema.Types.ObjectId
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
    created:
      type: Date
      default: Date.now
    updated:
      type: Date
      default: Date.now
  Place.methods.format = ->
    data = @toJSON()
    delete data.password
    return data
  Place
