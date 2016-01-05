_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')
sockSrv = require('../services/socket')

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
needCreate = Object.keys(createValidator)
canEdit = needCreate

class API

  createDevice: (req, callback) ->
    params = _.pick req.body, needCreate
    db.device.create params, (err, device)->
      callback(err, device)
  @::createDevice.route = ['post', '/devices']
  @::createDevice.before = [
    userSrv.isRoot
  ]
  @::createDevice.validator = createValidator

  editDevice: (req, callback) ->
    { _id } = req.body
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
    { uid, order } = req.query
    sockSrv.start(uid, 10, callback)
  @::order.route = ['get', '/devices/order']
  @::order.before = [
    userSrv.isRoot
  ]

  fetchDevices: (req, callback) ->
    user = req._data.user
    role = user.role
    _placeId = req.query._placeId
    console.log 'fetchDevices._placeId', _placeId
    if role is 'root'
      cons = {}
    else
      cons = _userId: _userId
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
            device.location = map["#{device._placeId}"].location
            device.place = map["#{device._placeId}"].name
            device
    .then (devices) ->
      console.log 'devices', devices
      callback(null, devices)
    .catch (e) ->
      console.log e.stack

  @::fetchDevices.route = ['get', '/devices']
  @::fetchDevices.before = [
    userSrv.isAgent
  ]

module.exports = new API
