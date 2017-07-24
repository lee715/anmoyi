_ = require('lodash')

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
    contacts:
      type: Schema.Types.Mixed
      default: []
    license: String

    password:
      type: String
      default: '888888'
    # agent admin root salesman
    role: String
    created:
      type: Date
      default: Date.now

  User.methods.hasOrder = ->
    @role in ['root', 'agent', 'salesman']

  User.methods.format = ->
    if @role in ['agent', 'salesman']
      data = @toJSON()
    else
      data = _.pick @, ['_id', 'name', 'phone', 'email', 'role', 'password']
    return data

  User