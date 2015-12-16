_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('./services/util')

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
canEdit = '_placeId price time discount remission name _userId'.split(' ')

class API

  createDevice: (req, callback) ->
    params = _.pick req.body, needCreate
    db.device.create params, callback
  @::createDevice.route = ['post', '/devices/create']
  @::createDevice.validator = createValidator

  editDevice: (req, callback) ->
    { _id } = req.body
    data = _.pick req.body, canEdit
    db.device.update
      _id: _id
    , data
    , callback
  @::editDevice.route = ['put', '/devices/edit']
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
  @::delDevice.route = ['delete', '/devices/del']

  fetchDevices: (req, callback) ->
    console.log 'fetchDevices session',req.session
    _userId = req.session._userId
    db.user.findOneAsync
      _id: _userId
    .then (user) ->
      role = user.role
      if role is 9
        cons = {}
      else
        cons = _userId: _userId
      console.log 'cons', cons
      db.device.findAsync cons
    .then (devices) ->
      map = {}
      ids = []
      devices.forEach (device) ->
        if device._userId
          ids.push "#{device._userId}"
      console.log 'ids', _.uniq(ids)
      db.user.findAsync
        _id: $in: _.uniq(ids)
      .then (users) ->
        users.forEach (user) ->
          map["#{user._id}"] = user.name
        devices = devices.map (device) ->
          device = _.pick device, deviceJson
          device.user = map["#{device._userId}"]
          device
        callback(null, devices)
    .catch (e) ->
      console.log e.stack

  @::fetchDevices.route = ['get', '/devices']

module.exports = new API
