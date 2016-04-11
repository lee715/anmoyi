db = require('limbo').use('anmoyi')
module.exports =
  init: (req, res, next) ->
    _userId = req.session._userId
    _placeId = req.session._placeId
    req._data = {}
    if _userId
      db.user.findOneAsync
        _id: _userId
      .then (user) ->
        if user
          console.log 'init', user
          req._data.user = user
        next()
    else if _placeId
      db.place.findOneAsync
        _id: _placeId
      .then (place) ->
        if place
          req._data.user = place
        next()
    else
      next()

  isRoot: (req, res, next) ->
    user = req._data.user
    if user and user.role is 'root'
      next()
    else
      res.status(403).send('Forbidden')

  isAgent: (req, res, next) ->
    user = req._data.user
    if user and user.role in ['agent', 'root']
      next()
    else
      res.status(403).send('Forbidden')

  isServer: (req, res, next) ->
    user = req._data.user
    if user and user.role in ['agent', 'root', 'server']
      next()
    else
      res.status(403).send('Forbidden')

  isLogined: (req, res, next) ->
    user = req._data.user
    console.log 'isLogined', user
    if user
      next()
    else
      res.status(403).send('Forbidden')
