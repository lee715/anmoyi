net = require('net');
config = require('config')
PORT = config.SOECKET_PORT or '7000'
db = require('limbo').use('anmoyi')
_ = require('lodash')
moment = require('moment')
Promise = require('bluebird')
redis = require('./redis')

updateDevice = (uid, status, income, wxTime) ->
  db.device.findOneAsync uid: uid
  .then (device) ->
    if device
      device.status = status
      device.income = income
      device.wxTime = wxTime
      device.statusUpdated = Date.now()
      device.save()

createTbOrder = (uid, total) ->
  db.device.findOneAsync uid: uid
  .then (device) ->
    db.order.createAsync
      uid: uid
      money: total
      _placeId: device._placeId
      _userId: device._userId
      status: "SUCCESS"
      serviceStatus: "ENDED"

record = (uid) ->
  key = (new Date()).toLocaleDateString()
  redis.incr("RECORD.#{uid}.#{key}")

class TbService

  constructor: (uid) ->
    @uid = uid
    @

  handle: (action, val) ->
    switch action
      when 'timebuy'
        unless @times
          @times = []
          @start = new Date
        @times.push val
        SOCKS.resOk(@uid)
        break
      when 'cashtotal'
        @serviceEnd(val)

  serviceEnd: (cash) ->
    end = new Date
    start = @start
    serviceTime = end - start
    buyTime = 0
    for t in @times
      buyTime += t*60*1000
    order =
      money: cash
      time: buyTime
      uid: @uid
    if buyTime < serviceTime
      order.status = 'SUCCESS'
    else
      order.status = 'ERROR'
    db.device.findOneAsync
      uid: @uid
    .then (device) ->
      order._userId = device._userId
      order._placeId = device._placeId
      order.deviceStatus = device.realStatus
      db.order.createAsync order
    .then ->
      SERVICES.remove(@uid)
    .catch (e) ->
      order.status = "DB_ERROR"
      db.order.create order, ->

SERVICES =
  remove: (uid) ->
    delete @[uid]

SOCKS =
  _cbs: {}
  _socks: {}

  resOk: (uid) ->
    sock = @get(uid)
    if sock
      sock.write("~#{uid}#OK\r")

  resSet: (uid, action, callback) ->
    sock = @get(uid)
    if sock
      @handleCB(uid, callback)
      sock.write("~#{uid}#set##{action}\r")

  resStart: (uid, time, callback) ->
    sock = @get(uid)
    console.log 'resStart:sock', uid, time
    if sock
      @handleCB(uid, callback)
      sock.write("~#{uid}#startup##{time}\r")

  handleCB: (uid, callback) ->
    unless @_cbs[uid]
      @_cbs[uid] = []
      @_cbs[uid].cb = (state, err) =>
        console.log 'cb called'
        cb = @_cbs[uid].shift()
        cb(null, !!state)
        console.log @_cbs[uid].length
        delete @_cbs[uid] unless @_cbs[uid].length
    @_cbs[uid].push callback

  cacheSock: (uid, sock) ->
    if uid and sock
      @_socks[uid] = sock

  get: (uid) ->
    @_socks[uid]

  handleMsg: (msg, sock) ->
    unless /^\~/.test(msg)
      return
    msg = msg.replace(/[^0-9a-zA-Z\#]+/g, '')
    arr = msg.split('#')
    arr[0] = arr[0].slice(-12)
    return if arr.length < 3
    @cacheSock(arr[0], sock)
    uid = arr[0]
    if @_cbs[uid]
      if arr.length is 4 and arr[3] is 'OK'
        @_cbs[uid].cb(true)
      else if arr.length is 4 and arr[3] isnt 'OK'
        @_cbs[uid].cb(false, arr[1])
      else
        @_cbs[uid].cb(false, 'NO_ANWSER')
    if arr.length is 3
      [uid, action, val] = arr
      return if val is 'OK'
      # unless SERVICES[uid]
      #   SERVICES[uid] = new TbService(uid)
      # SERVICES[uid].handle(action, val)
      switch action.toLowerCase()
        when 'cashtotal'
          createTbOrder(uid, val)
    else if arr.length > 3
      # status in ['idle', 'work', 'fault']
      [uid, tbCount, wxTime, status, val] = arr
      status = status.toLowerCase()
      return if status is 'ok'
      if uid is '08d833f62d36'
        record(uid)
      if status in ['free', 'idle']
        status = 'idle'
      else if status isnt 'work'
        status = 'fault'
      wxTime = +wxTime.slice(1)
      updateDevice(uid, status, tbCount, wxTime)
      recordStatus(uid, status)
      # incomeSrv(uid, tbCount, wxTime)
      SOCKS.resOk(uid)

STATUS_VALS =
  idle: "2"
  work: '3'
  fault: "1"

recordStatus = (uid, status) ->
  val = STATUS_VALS[status] or "9"
  now = new Date
  start = moment().startOf('day').toDate()
  db.status.findOneAsync
    created: start
  .then (status) ->
    unless status
      db.status.createAsync
        uid: uid
        created: start
    else
      status
  .then (one) ->
    padding = parseInt((now - start)/(1000*30))
    padded = one.status.length
    toAdd = val
    i = padding - padded
    if i > 0
      while i--
        toAdd = "0" + toAdd
    one.status += toAdd
    one.save()

net.createServer( (sock) ->
  console.log "CONNECTED: #{sock.remoteAddress}:#{sock.remotePort}"
  sock.on 'data', (data) ->
    SOCKS.handleMsg((new Buffer(data)).toString('utf8'), sock)
  sock.on 'close', ->
    console.log "CLOSED: #{sock.remoteAddress}:#{sock.remotePort}"
).listen(PORT, ->
  console.log('Server listening on:'+ PORT)
)

apis = module.exports =
  start: ->
    console.log 'socket:start', arguments
    SOCKS.resStart.apply(SOCKS, arguments)
  set: ->
    console.log 'socket:set', arguments
    SOCKS.resSet.apply(SOCKS, arguments)

Promise.promisifyAll(apis)