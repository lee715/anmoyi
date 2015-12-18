
module.exports = (Schema) ->
  new Schema
    status:
      type: String
      default: ''
    uid: String
    created:
      type: Date
      default: Date.now
