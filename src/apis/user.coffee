_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('../services/util')
userSrv = require('../services/user')

pluck = (keys) ->
  (arr) ->
    rt = []
    arr.forEach (item) ->
      rt.push _.pick item, keys
    return rt

formatUser = (user) ->
  delete user.password
  return user

class API

  login: (req, callback) ->
    { email, password } = req.body
    isPlace = false
    db.user.findOneAsync
      email: email
    .then (user) ->
      unless user
        db.place.findOneAsync
          email: email
        .then (place) ->
          if place
            isPlace = true
          place
      else
        user
    .then (user) ->
      unless user
        req.res.status(401).send('user')
      else if user and user.password isnt password
        req.res.status(401).send('password')
      else
        if isPlace
          req.session._placeId = "#{user._id}"
        else
          req.session._userId = "#{user._id}"
        req.res.json(formatUser(user))
  @::login.route = ['post', '/login']
  @::login.validator =
    email: "Email:required"
    password: "String:required"

  logout: (req, callback) ->
    req.session._userId = ''
    req.res.redirect('/login')
  @::logout.route = ['get', '/logout']

  me: (req, callback) ->
    _userId = req.session._userId
    if _userId
      db.user.findOne
        _id: _userId
      , (err, user) ->
        if err or not user
          req.res.status(401).send('user')
        else
          callback(null, formatUser(user.toJSON()))
    else
      req.res.status(401).send('user')
  @::me.route = ['get', '/users/me']

  fetchUsers: (req, callback) ->
    db.user.findAsync {}
    .then (users) ->
      callback(null, _.map(users, (user) -> return user.format()))
  @::fetchUsers.route = ['get', '/users']
  @::fetchUsers.before = [
    userSrv.isRoot
  ]

  fetchAgents: (req, callback) ->
    db.user.findAsync
      role: 'agent'
    .then (users) ->
      callback(null, _.map(users, (user) -> return user.format()))
  @::fetchAgents.route = ['get', '/agents']
  @::fetchAgents.before = [
    userSrv.isRoot
  ]

  createUser: (req, callback) ->
    { email, name, role } = req.body
    unless email and name and role
      return req.res.status(302).send('paramErr')
    if role is 'agent'
      data = _.pick req.body, ['name', 'company', 'phone', 'location', 'email', 'mailAddress', 'qq', 'bankName', 'bankAccount', 'role']
    else
      data = _.pick req.body, ['name', 'phone', 'email', 'role']
    data.password = parseInt((Math.random()*1000000-1))
    db.user.findOneAsync
      email: email
    .then (user) ->
      if user
        return req.res.status(302).send('emailUsed')
      else
        db.user.createAsync data
        .then (user) ->
          callback(null, user.toJSON())
    .catch ->
      req.res.status(400).send('systemErr')
  @::createUser.route = ['post', '/users/create']
  @::createUser.before = [
    userSrv.isRoot
  ]

  editUser: (req, callback) ->
    { email } = req.body
    unless email
      return req.res.status(302).send('paramErr')
    db.user.findOneAndUpdate
      email: email
    , req.body, (err, user) ->
      if err or not user
        req.res.status(400).send('paramErr')
      else
        callback(null, formatUser(user))
  @::editUser.route = ['post', '/users/edit']

module.exports = new API
