
module.exports = (Schema) ->
  User = new Schema
    name:
      type: String
      default: 'default'
    phone: String
    email: String
    # agent only
    location: String
    company: String
    mailAddress: String
    qq: String
    bankName: String
    bankAccount: String

    password:
      type: String
      default: '888888'
    role:
      type: Number
      default: 0
    # agent admin root salesman
    type: String
    created:
      type: Date
      default: Date.now

  User.methods.hasOrder = ->
    @type in ['root', 'agent']
  User