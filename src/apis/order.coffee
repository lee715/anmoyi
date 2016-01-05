_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
moment = require('moment')

class API

  getOrders: (req, callback) ->
    user = req._data.user
    startDate = req.query.startDate
    endDate = req.query.endDate
    if user.role is 'root'
      cons = {}
    else
      cons = _userId: user._id
    if startDate or endDate
      cons.created = {}
      cons.created.$gt = startDate if startDate
      cons.created.$lt = endDate if endDate
    db.order.findAsync cons
    .then (orders) ->
      alienMap = {}
      openIds = _.pluck orders, 'openId'
      db.alien.findAsync
        openId: $in: openIds
      .then (aliens) ->
        aliens.forEach (alien) ->
          alienMap[alien.openId] = alien
        orders = orders.map (order) ->
          order = order.toJSON()
          order.username = alienMap[order.openId].name
          order
        orders
    .then (orders) ->
      agentMap = {}
      ids = _.pluck orders, '_agentId'
      db.user.findAsync
        _id: $in: ids
      .then (users) ->
        users.forEach (user) ->
          agentMap[user._id] = user
        orders = orders.map (order) ->
          order.agentName = agentMap["#{order._agentId}"]?.name
          order
        orders = _.sortByOrder(orders, ['created'], ['desc'])
        callback(null, orders)
    .catch (e) ->
      console.log e
      callback(new Error('systemErr'))
  @::getOrders.route = ['get', '/orders']
  @::getOrders.before = [
    userSrv.isAgent
  ]

  section: (req, callback) ->
    user = req._data.user
    { startDate, endDate, type, _placeId } = req.query
    cons = {}
    if type is 'place'
      if user.role is 'agent'
        cons._agentId = user._id
    else if type is 'device'
      cons._placeId = _placeId
    db[type].findAsync cons
    .then (data) ->
      ids = _.pluck data, '_id'
      match = status: 'SUCCESS'
      if type is 'place'
        match._placeId = $in: ids
      else
        uids = _.pluck data, 'uid'
        match.uid = $in: uids
      if startDate or endDate
        match.created = {}
        match.created.$gt = moment(startDate).startOf('day') if startDate
        match.created.$lt = moment(endDate).endOf('day') if endDate
      db.order.findAsync match
    .then (orders) ->
      totals = {}
      orders.forEach (order) ->
        if type is 'place'
          key = "#{order._placeId}"
        else
          key = "#{order.uid}"
        unless totals[key]
          totals[key] = 0
        totals[key] += order.money
      callback(null, totals)

  @::section.route = ['get', '/section']
  @::section.before = @::getOrders.before = [
    userSrv.isAgent
  ]

module.exports = new API