_ = require('lodash')
db = require('limbo').use('anmoyi')
userSrv = require('../services/user')

class API

  createType: (req, callback) ->
    { name, price, time } = req.body
    unless name and price and time
      return req.res.status(400).send('paramErr')
    data = _.pick(req.body, ['name', 'price', 'time'])
    db.type.findOneAndUpdateAsync
      name: name
    , data
    ,
      upsert: true
      new: true
    .then (type) ->
      callback(null, type)
    .catch (e) ->
      callback(e)
  @::createType.route = ['post', '/types']
  @::createType.before = [
    userSrv.isRoot
  ]

  getTypes: (req, callback) ->
    db.type.find {}, callback
  @::getTypes.route = ['get', '/types']

module.exports = new API
