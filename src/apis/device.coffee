_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
sockSrv = require('../services/socket')
moment = require('moment')
Promise = require('bluebird')

pluck = (keys) ->
  (arr) ->
    rt = []
    arr.forEach (item) ->
      rt.push _.pick item, keys
    return rt

deviceJson = ['_id', 'lastUsed', 'uid', '_userId', 'created', 'updated', 'place', 'location', 'price', 'status', 'discount', 'remission', 'income']
createValidator =
  _placeId: "ObjectId"
  price: "Number"
  time: "Number"
  discount: "Number"
  remission: "Number"
  uid: "String:required"
  name: "String:required"
  _userId: "ObjectId:required"
  type: "String"
needCreate = Object.keys(createValidator)
canEdit = needCreate

class API

  createDevice: (req, callback) ->
    params = _.pick req.body, needCreate
    if(params.type == 'pulse')
      params.time = 1
    _placeId = req.body._placeId
    unless params.uid
      return req.res.status(302).send('paramErr')
    db.place.findOneAsync
      _id: _placeId
    .then (place) ->
      params._userId = place._agentId
      db.device.createAsync params
    .then (device)->
      callback(null, device)
    .catch (e) ->
      callback(e)
  @::createDevice.route = ['post', '/devices']
  @::createDevice.before = [
    userSrv.isRoot
  ]
  @::createDevice.validator = createValidator

  editDevice: (req, callback) ->
    { _id } = req.body
    unless req.body.uid
      return req.res.status(302).send('paramErr')
    data = _.pick req.body, canEdit
    db.device.update
      _id: _id
    , data
    , callback
  @::editDevice.route = ['put', '/devices']
  @::editDevice.validator =
    _id: "ObjectId:required"
    $or:
      _placeId: "ObjectId"
      price: "Number"
      time: "Number"
      discount: "Number"
      remission: "Number"
      name: "String"
      _userId: "ObjectId"

  delDevice: (req, callback) ->
    { _id } = req.body
    db.device.remove _id: _id, callback
  @::delDevice.route = ['delete', '/devices']

  order: (req, callback) ->
    { uid, order, time } = req.query
    sockSrv.start(uid, time or 10, (err) ->
      return callback(err) if err
      db.device.update
        uid: uid
      , status: 'work'
      ,
        upsert: false
        new: false
      , (err, rt) ->
        callback(err, 'ok')
    )
  @::order.route = ['get', '/devices/order']
  @::order.before = [
    userSrv.isRoot
  ]

  fetchDevices: (req, callback) ->
    user = req._data.user
    role = user.role
    _placeId = req.query._placeId
    if role is 'root'
      cons = {}
    else
      cons = _userId: user._id
    if _placeId
      cons._placeId = _placeId
    db.device.findAsync cons
    .then (devices) ->
      map = {}
      userids = []
      placeids = []
      devices.forEach (device) ->
        device.status = device.realStatus
        if device._userId
          userids.push "#{device._userId}"
        if device._placeId
          placeids.push "#{device._placeId}"
      db.user.findAsync
        _id: $in: _.uniq(userids)
      .then (users) ->
        users.forEach (user) ->
          map["#{user._id}"] = user.name
        devices.map (device) ->
          device = device.toJSON()
          device.user = map["#{device._userId}"]
          device
      .then (devices) ->
        db.place.findAsync
          _id: $in: _.uniq(placeids)
        .then (places) ->
          places.forEach (place) ->
            map["#{place._id}"] = place
          devices.map (device) ->
            device.location = map["#{device._placeId}"]?.location
            device.place = map["#{device._placeId}"]?.name
            device
    .map (device) ->
      if _placeId
        now = new Date
        today = moment().startOf('day').toDate()
        yestoday = moment().add(-1, 'day').startOf('day').toDate()
        device.total = {}
        Promise.map [[now, today], [today, yestoday]], ([to, from]) ->
          db.order.findAsync
            created:
              $gt: from
              $lt: to
            uid: device.uid
            status: 'SUCCESS'
            serviceStatus: $in: ['STARTED', 'ENDED']
          .then (orders) ->
            total = {}
            orders.forEach (order) ->
              total[order.mode] = 0 unless total[order.mode]
              total[order.mode] += order.money
            total
        .then (totals) ->
          device.total.today = totals[0]
          device.total.yestoday = totals[1]
          device
      else
        device
    .then (devices) ->
      devices = _.sortBy(devices, (device) -> return device.name)
      callback(null, devices)
    .catch (e) ->
      callback(e)

  @::fetchDevices.route = ['get', '/devices']
  @::fetchDevices.before = [
    userSrv.isAgent
  ]

module.exports = new API
