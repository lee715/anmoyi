_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
moment = require('moment')

class API

  create: (req, callback) ->
    data = req.body
    db.place.createAsync data
    .then (place) ->
      callback(null, place.toJSON())
  @::create.route = ['post', '/places']
  @::create.before = [
    userSrv.isRoot
  ]

  delPlace: (req, callback) ->
    { _id } = req.body
    db.place.remove _id: _id, callback
  @::delPlace.route = ['delete', '/places']

  update: (req, callback) ->
    { _id } = req.body
    console.log req.body
    db.place.update
      _id: _id
    , req.body
    , callback
  @::update.route = ['put', '/places']
  @::update.before = [
    userSrv.isRoot
  ]

  get: (req, callback) ->
    user = req._data.user
    if user.role is 'root'
      cons = {}
    else
      cons = _agentId: user._id
    db.place.findAsync cons
    .then (places) ->
      callback(null, _.map(places, (place) -> return place.format()))
  @::get.route = ['get', '/places']
  @::get.before = [
    userSrv.isAgent
  ]

  getPlacesWithStatistic: (req, callback) ->
    user = req._data.user
    if user.role is 'root'
      cons = {}
    else
      cons = _agentId: user._id
    db.place.findAsync cons
    .map (place) ->
      place = place.format()
      db.device.findAsync
        _placeId: place._id
      .then (devices) ->
        place.device = {}
        place.device.total = devices.length
        place.device.normal = 0
        devices.forEach (device) ->
          if device.realStatus in ['idle', 'work']
            place.device.normal++
        now = new Date
        today = moment().startOf('day').toDate()
        yestoday = moment().add(-1, 'day').startOf('day').toDate()
        thisWeek = moment().startOf('isoWeek').toDate()
        lastWeek = moment().add(-1, 'week').startOf('isoWeek').toDate()
        thisMonth = moment().startOf('month').toDate()
        lastMonth = moment().add(-1, 'month').startOf('month').toDate()
        [[now, today], [today, yestoday], [now, thisWeek], [thisWeek, lastWeek], [now, thisMonth], [thisMonth, lastMonth]]
      .map ([from, to]) ->
        db.order.findAsync
          created:
            $gt: from
            $lt: to
          _placeId: place._id
          status:
            $in: ['SUCCESS', 'STARTED']
        .then (orders) ->
          moneys = _.pluck orders, 'money'
          total = _.reduce(moneys, (a, b) -> a + b) or 0
      .then (moneys) ->
        place.moneys = moneys
        place
    .then (places) ->
      callback(null, places)
    .catch (e) ->
      console.log e.stack
  @::getPlacesWithStatistic.route = ['get', '/places/statistic']
  @::getPlacesWithStatistic.before = [
    userSrv.isAgent
  ]

  getById: (req, callback) ->
    _id = req.params._id
    console.log 'getById', _id
    db.place.findOneAsync
      _id: _id
    .then (place) ->
      callback(null, place and place.format())
  @::getById.route = ['get', '/places/:_id']
  @::getById.before = [
    userSrv.isLogined
  ]

  reconciliation: (req, callback) ->
    user = req._data.user
    {_placeId} = req.params
    unless user.role in ['agent', 'place', 'root'] and _placeId
      return res.status(403).send('Forbidden')
    db.place.findAsync
      _id: _placeId
    .then (place) ->
      _agentId = place._agentId
      if user.role is 'agent' and "#{place._agentId}" is "#{user._id}" or user.role in ['place', 'root']
        months = [
          # for test
          moment().startOf('month')
          moment().startOf('month').add(-1, 'month')
          moment().startOf('month').add(-2, 'month')
          moment().startOf('month').add(-3, 'month')
        ]
      else
        []
    .map (start) ->
      end = start.clone().endOf('month')
      db.order.findAsync
        _placeId: _placeId
        created:
          $gt: start.toDate()
          $lt: end.toDate()
      .then (orders) ->
        total = 0
        orders.forEach (order) ->
          total += +order.money
        total
    .then (totals) ->
      callback(null, totals)

  @::reconciliation.route = ['get', '/reconciliation/:_placeId']
  @::reconciliation.before = [
    userSrv.isLogined
  ]

module.exports = new API