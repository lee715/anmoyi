
module.exports = (Schema) ->
  Alien = new Schema
    name: String
    city: String
    province: String
    openId: String
    country: String
    created:
      type: Date
      default: Date.now

  Alien