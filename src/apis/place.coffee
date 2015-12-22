_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')

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

  update: (req, callback) ->
    { _id } = req.body
    db.place.findOneAndUpdate
      _id: _id
    ,
      req.body
    ,
      new: false
      upsert: false
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
module.exports = new API