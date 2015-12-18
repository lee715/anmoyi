
module.exports = (Schema) ->
  new Schema
    name: String
    province: String
    city: String
    county: String
    address: String
    # 客服人员id
    _agentId: Schema.Types.ObjectId
    # 代理商id
    _userId: Schema.Types.ObjectId
    contacts:
      type: Schema.Types.Mixed
      default: []
    created:
      type: Date
      default: Date.now
    updated:
      type: Date
      default: Date.now
