_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
moment = require('moment')
Promise = require('bluebird')

class API

  getOrders: (req, callback) ->
    { startDate, endDate } = req.query
    user = req._data.user
    startDate = req.query.startDate
    endDate = req.query.endDate
    if not startDate or not endDate or not u.isDate(startDate) or not u.isDate(endDate)
      return callback(new Error('invalid date'))
    Promise
    .resolve()
    .then ->
      cons = {}
      if user.role is 'agent'
        cons._userId = user._id
      else if user.role is 'salesman'
        db.place.findAsync
          _salesmanId: user._id
        .then (places) ->
          cons._placeId = $in: _.map(places, '_id')
      if startDate or endDate
        cons.created = {}
        cons.created.$gt = moment(startDate).toDate() if startDate
        cons.created.$lt = moment(endDate).toDate() if endDate
      return cons
    .then (cons) ->
      db.order.findAsync(cons)
    .then (orders) ->
      orders = _.sortByOrder(orders, ['created'], ['desc'])
      orders = orders.slice(0, 3000)
      alienMap = {}
      openIds = _.pluck orders, 'openId'
      db.alien.findAsync
        openId: $in: openIds
      .then (aliens) ->
        aliens.forEach (alien) ->
          alienMap[alien.openId] = alien
        orders = orders.map (order) ->
          order = order.toJSON()
          order.username = alienMap[order.openId]?.name
          order
        orders
    .then (orders) ->
      userMap = {}
      deviceMap = {}
      ids = []
      uids = []
      orders.forEach (order) ->
        ids.push "#{order._placeId}" if order._placeId
        ids.push "#{order._userId}" if order._userId
        uids.push "#{order.uid}" if order.uid
      ids = _.uniq(ids)
      uids = _.uniq(uids)
      db.user.findAsync
        _id: $in: ids
      .then (users) ->
        db.place.findAsync
          _id: $in: ids
        .then (places) ->
          db.device.findAsync
            uid: $in: uids
          .then (devices) ->
            devices.forEach (device) ->
              deviceMap["#{device.uid}"] = device
            users.concat(places).forEach (user) ->
              userMap["#{user._id}"] = user
            orders = orders.map (order) ->
              order.agentName = userMap["#{order._userId}"]?.name
              order.placeName = userMap["#{order._placeId}"]?.name
              order.deviceName = deviceMap["#{order.uid}"]?.name
              order
            # orders = _.sortByOrder(orders, ['created'], ['desc'])
            callback(null, orders)
    .catch (e) ->
      callback(new Error('systemErr'))
  @::getOrders.route = ['get', '/orders']
  @::getOrders.before = [
    userSrv.isServer
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
      match =
        status: 'SUCCESS'
        serviceStatus: $in: ['STARTED', 'ENDED']
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
      Object.keys(totals).forEach (key) ->
        totals[key] = totals[key].toFixed(2)
      callback(null, totals)

  @::section.route = ['get', '/section']
  @::section.before = [
    userSrv.isAgent
  ]

module.exports = new API