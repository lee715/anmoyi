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

    password:
      type: String
      default: '888888'
    # agent admin root salesman
    role: String
    created:
      type: Date
      default: Date.now

  User.methods.hasOrder = ->
    @type in ['root', 'agent']

  User.methods.format = ->
    if @role is 'agent'
      data = _.pick @, ['name', 'company', 'phone', 'location', 'email', 'mailAddress', 'qq', 'bankName', 'bankAccount', 'role']
    else
      data = _.pick @, ['name', 'phone', 'email', 'role']
    return data

  User