_ = require('lodash')
db = require('limbo').use('anmoyi')
util = require('../services/util')
userSrv = require('../services/user')
redis = require('../services/redis')
sockSrv = require('../services/socket')

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

  delType: (req, callback) ->
    name = req.query.name
    db.type.remove name: name, callback
  @::delType.route = ['delete', '/types']

  createCoupon: (req, callback) ->
    {time, count} = req.body
    rt = []
    while (count-- > 0)
      key = util.randomString(12)
      redis.setex("coupon:#{key}", 60 * 60 * 24 * 30, time || 10, ->)
      rt.push(key)
    callback(null, rt)
  @::createCoupon.route = ['post', '/coupons']
  @::createCoupon.before = [
    userSrv.isRoot
  ]

  payByCoupon: (req, callback) ->
    {coupon, uid} = req.body
    redis.getAsync("coupon:#{coupon}")
      .then (time) ->
        return callback(new Error('coupon expired')) if (!time)
        sockSrv.startAsync(uid, time, (err) ->
          return callback(err) if (err)
          redis.del("coupon:#{coupon}")
          callback(null, time)
        )
  @::payByCoupon.route = ['post', '/coupons:start']

module.exports = new API
