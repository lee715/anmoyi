errSrv = require('./services/err')

module.exports = (router, controller, middlewares = [], prefix = '') ->
  for funName, func of controller
    continue if typeof func isnt 'function'
    continue unless func.route
    do (func) ->
      {route, before, after} = func
      [method, urls] = func.route

      urlsStr = urls.toString()
      urlsStr.split(',').forEach (url) ->
        url = prefix + url.replace(/:_id/g, ':_id([0-9a-fA-F]{24})')
        console.log url
        router[method] url, middlewares.concat(before or [], wrap(func), after or [])

  # error handler
  router.use (err, req, res, next) ->
    if err
      if typeof err is 'string'
        err = errSrv(err)
      res.status(400).json(err)
    else
      next()

  router.use (req, res, next) ->
    if req.template
      res.render(req.template, req.result)
    else if req.redirect
      console.log 'redirect:', req.redirect
      res.redirect(req.redirect)
    else if req.result?
      if typeof req.result is 'string'
        res.send(req.result)
      else res.json(req.result)
    else next()

wrap = (func) -> (req, res, next) ->
  func req, (err, result) ->
    if err is 'noContent'
      return res.status(204).json({})
    return next(err) if err?
    req.result = if result instanceof Array
      result.map _toJSON
    else
      _toJSON result
    next()

_toJSON = (obj) ->
  return obj unless obj?.toJSON?
  return obj.toJSON()