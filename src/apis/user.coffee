_ = require('lodash')
db = require('limbo').use('anmoyi')
u = require('./services/util')

pluck = (keys) ->
  (arr) ->
    rt = []
    arr.forEach (item) ->
      rt.push _.pick item, keys
    return rt

formatUser = (user) ->
  return _.pick(user, ['_id', 'role', 'email', 'name', 'company', 'phone', 'location'])

class API

  login: (req, callback) ->
    { email, password } = req.body
    db.user.findOne
      email: email
    , (err, user) ->
      if err or not user
        req.res.status(401).send('user')
      else if user and user.password isnt password
        req.res.status(401).send('password')
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
          callback(null, formatUser(user))
    else
      req.res.status(401).send('user')
  @::me.route = ['get', '/users/me']

  fetchUsers: (req, callback) ->
    db.user.findAsync {}
    .then (users) ->
      callback(null, users)
  @::fetchUsers.route = ['get', '/users']


  createUser: (req, callback) ->
    { email, name } = req.body
    data = _.pick req.body, ['name', 'company', 'phone', 'location', 'email']
    unless email and name
      return req.res.status(302).send('paramErr')
    options =
      new: true
      upsert: true
    db.user.findOneAsync
      email: email
    .then (user) ->
      if user
        return req.res.status(302).send('emailUsed')
      else
        db.user.createAsync data
        .then (user) ->
          callback(null, formatUser(user))
    .catch ->
      req.res.status(400).send('systemErr')
  @::createUser.route = ['post', '/users/create']

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
