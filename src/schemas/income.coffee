
module.exports = (Schema) ->
  new Schema
    income:
      type: Number
      default: 0
    wxTime:
      type: Number
      default: 0
    uid: String
    type: String
    created:
      type: Date
      default: Date.now
