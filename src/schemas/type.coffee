
module.exports = (Schema) ->
  Type = new Schema
    name: String
    price: String
    time: String
    created:
      type: Date
      default: Date.now

  Type