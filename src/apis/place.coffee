_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
moment = require('moment')
modes =
  hotel:
    price: '10,30,50'
    time: '5,60,720'
  airport:
    price: '2'
    time: '30'
  test:
    price: '0.02'
    time: '60'
  changsha:
    price: '0.01,0.03,0.06'
    time: '10,30,60'
class API

  create: (req, callback) ->
    {email} = req.body
    mode = req.body.mode
    unless email and mode
      return req.res.status(302).send('paramErr')
    db.place.findOneAsync
      email: email
    .then (place) ->
      if place
        return req.res.status(302).send('emailUsed')
      else
        db.type.findOneAsync
          _id: mode
        .then (type) ->
          unless type
            return callback(new Error('type not found'))
          req.body.price = type.price
          req.body.time = type.time
          req.body.mode = type.name
          db.place.createAsync req.body
          .then (place) ->
            callback(null, place.toJSON())
    .catch callback
  @::create.route = ['post', '/places']
  @::create.before = [
    userSrv.isRoot
  ]

  delPlace: (req, callback) ->
    { _id } = req.body
    db.place.remove _id: _id, callback
  @::delPlace.route = ['delete', '/places']
  @::delPlace.before = [
    userSrv.isRoot
  ]

  update: (req, callback) ->
    { email } = req.body
    delete req.body._id
    delete req.body.email
    mode = req.body.mode
    db.type.findOneAsync
      _id: mode
    .then (type) ->
      unless type
        return callback(new Error('type not found'))
      req.body.price = type.price
      req.body.time = type.time
      req.body.mode = type.name
      db.place.findOneAndUpdate
        email: email
      , req.body
      ,
        upsert: false
        new: false
      , callback
    .catch callback
  @::update.route = ['put', '/places']
  @::update.before = [
    userSrv.isRoot
  ]

  get: (req, callback) ->
    user = req._data.user
    if user.role is 'root'
      cons = {}
    else if user.role is 'agent'
      cons = _agentId: user._id
    else
      cons = _salesmanId: user._id
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
        place
    .then (places) ->
      callback(null, places)
  @::get.route = ['get', '/places']
  @::get.before = [
    userSrv.isLogined
  ]

  getPlacesWithStatistic: (req, callback) ->
    user = req._data.user
    if user.role is 'root'
      cons = {}
    else if user.role is 'agent'
      cons = _agentId: user._id
    else
      cons = _salesmanId: user._id
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
        [[now, today], [today, yestoday], [now, thisWeek], [thisWeek, lastWeek]]
      .map ([to, from]) ->
        db.order.findAsync
          created:
            $gt: from
            $lt: to
          _placeId: place._id
          status: 'SUCCESS'
          serviceStatus: $in: ['STARTED', 'ENDED']
        .then (orders) ->
          moneys = _.pluck orders, 'money'
          total = _.reduce(moneys, (a, b) -> a + b) or 0
      .then (moneys) ->
        place.moneys = moneys
        place
    .then (places) ->
      callback(null, places)
    .catch (e) ->
      callback(e)
  @::getPlacesWithStatistic.route = ['get', '/places/statistic']
  @::getPlacesWithStatistic.before = [
    userSrv.isLogined
  ]

  getById: (req, callback) ->
    _id = req.params._id
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
    unless user.role in ['agent', 'place', 'root', 'salesman'] and _placeId
      return res.status(403).send('Forbidden')
    p = null
    db.place.findOneAsync
      _id: _placeId
    .then (place) ->
      p = place.p
      if (user.role is 'agent' and "#{place._agentId}" is "#{user._id}") or (user.role in ['place', 'root', 'salesman'])
        months = [
          [moment().startOf('month'), moment().startOf('day')]
          [moment().startOf('month').add(-1, 'month'), moment().startOf('month')]
          [moment().startOf('month').add(-2, 'month'), moment().startOf('month').add(-1, 'month')]
        ]
      else
        []
    .map ([start, end]) ->
      db.order.findAsync
        _placeId: _placeId
        status: 'SUCCESS'
        serviceStatus: 'STARTED'
        created:
          $gt: start.toDate()
          $lt: end.toDate()
      .then (orders) ->
        total = 0
        orders.forEach (order) ->
          total += +order.money
        (total*p/100).toFixed(2)
    .then (totals) ->
      callback(null, totals)

  @::reconciliation.route = ['get', '/reconciliation/:_placeId']
  @::reconciliation.before = [
    userSrv.isLogined
  ]

module.exports = new API