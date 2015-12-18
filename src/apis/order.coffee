_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')

class API

  getOrders: (req, callback) ->
    _userId = req.session._userId
    db.user.findOneAsync
      _id: _userId
    .then (user) ->
      if user.hasOrder()
        if user.role > 5
          cons = {}
        else
          cons = _userId: user._id
        db.order.findAsync cons
      else
        []
    .then (orders) ->
      alienMap = {}
      openIds = _.pluck orders, 'openId'
      console.log 'getOrders.openIds', openIds
      db.alien.findAsync
        openId: $in: openIds
      .then (aliens) ->
        console.log 'getOrders.aliens', aliens
        aliens.forEach (alien) ->
          alienMap[alien.openId] = alien
        orders = orders.map (order) ->
          console.log alienMap[order.openId].name
          order = order.toJSON()
          order.username = alienMap[order.openId].name
          order
        callback(null, orders)
    .catch (e) ->
      console.log e
      callback(new Error('systemErr'))
  @::getOrders.route = ['get', '/orders']


module.exports = new API