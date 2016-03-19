
module.exports = (Schema) ->
  Alien = new Schema
    name: String
    city: String
    province: String
    openId: String
    country: String
    money:
      type: Number
      default: 0
    created:
      type: Date
      default: Date.now

  Alien