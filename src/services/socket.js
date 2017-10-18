'use strict'

const net = require('net')
const config = require('config')
const db = require('limbo').use('anmoyi')
const redis = require('./redis')

const sockMap = {}

const sockCol = module.exports = {
  get: (uid) => {
    if (!uid) return null
    return sockMap[uid]
  },

  ensureAgent: (uid, sock) => {
    if (sockMap[uid]) {
      sockMap[uid].sock = sock
      return sockMap[uid]
    }
    sockMap[uid] = new SockAgent(uid, sock)
    sock.uid = uid
    return sockMap[uid]
  },

  closeSock: (sock) => {
    if (sock.uid) {
      sockMap[sock.uid] = null
      sock.uid = null
    }
  },

  start: (uid, time, callback) => {
    let sock = sockCol.get(uid)
    if (!sock) return callback(new Error('sock not found'))
    sock.sendStart(time, (err) => {
      if (err) callback(err)
      callback(null, 'started')
    })
  },

  startAsync: (uid, time) => {
    console.log('start device', uid, time)
    return new Promise((resolve, reject) => {
      let sock = sockCol.get(uid)
      if (!sock) reject(new Error('sock not found'))
      sock.sendStart(time, (err) => {
        if (err) reject(err)
        resolve(null, 'started')
      })
    })
  }
}

class SockAgent {
  constructor (uid, sock) {
    this.sock = sock
    this.uid = uid
    return this
  }

  handleMsg (msg) {
    switch (msg.type) {
      case 'OP_RES':
        this.doCache(null, 'ok')
        break
      case 'STATUS':
        this.record(msg)
        this._ok()
        break
    }
  }

  sendStart (time, callback) {
    let self = this
    // 如果有指令正在执行，报错
    if (this._timer) return callback(new Error('command is running'))
    let timer = setInterval(function () {
      self._start(time)
    }, 3000)
    this._start(time)
    let timeoutTimer = setTimeout(() => {
      console.log('start timeout', this.uid, time)
      this.doCache(new Error('start timeout'))
      this.sock.end()
    }, 1000 * 60 * 3)
    this.cache(callback, timer, timeoutTimer)
  }

  _start (time) {
    console.log('_start', this.uid, time, `~${this.uid}#startup#${time}\r`)
    this.sock.write(`~${this.uid}#startup#${time}\r`)
  }

  _ok () {
    this.sock.write(`~${this.uid}#OK\r`)
  }

  cache (fn, timer, timeoutTimer) {
    this._cache = fn
    this._timer = timer
    this._timeoutTimer = timeoutTimer
  }

  doCache (err, data) {
    console.log('doCache', err, data)
    this._cache && this._cache(err, data)
    this._timer && clearInterval(this._timer)
    this._timeoutTimer && clearTimeout(this._timeoutTimer)
    this._timer = null
    this._cache = null
  }

  clearCache () {
    this._cache = null
    this._timer && clearInterval(this._timer)
    this._timeoutTimer && clearTimeout(this._timeoutTimer)
    this._timer = null
  }

  record (msg) {
    db.device.update({
      uid: msg.uid
    }, {
      status: msg.status,
      wxTime: msg.wxTime,
      statusUpdated: Date.now()
    }, {upsert: true}, function (err) {
      if (err) console.log(err)
    })
  }

}

net.createServer( function (sock) {
  console.log `CONNECTED: ${sock.remoteAddress}:${sock.remotePort}`

  sock.on('data', function (data) {
    let msg = Buffer.from(data).toString('utf8')
    let _msg = formatMsg(msg)
    if (!_msg || !_msg.uid) {
      return console.warn('ignored msg: ' + msg, _msg)
    }
    let sa = sockCol.ensureAgent(_msg.uid, sock)
    sa.handleMsg(_msg)
  })

  sock.on('close', function () {
    console.log `CLOSED: ${sock.remoteAddress}:${sock.remotePort}`
    sockCol.closeSock(sock)
  })

  sock.on('end', function () {
    console.log('sock end')
    sockCol.closeSock(sock)
    sock.end()
  })

  sock.on('error', function (err) {
    console.log('sock error', err)
    sockCol.closeSock(sock)
    sock.end()
  })

}).listen(config.sockport || 7000, function () {
  console.log('tcp server listening on:'+ (config.sockport || 7000))
})

function formatMsg (msg) {
  if (!/^\~/.test(msg)) return null
  msg = msg.replace(/[^0-9a-zA-Z\#]+/g, '')
  let arr = msg.split('#')
  if (arr.length < 3) return null
  let formated = {
    uid: arr[0].slice(-12)
  }
  if (arr[3]) arr[3] = arr[3].toLowerCase()
  if (arr.length === 4) {
    if (arr[3] === 'ok') {
      formated.isOk = true
      formated.type = 'OP_RES'
    } else {
      if (['free', 'idle'].includes(arr[3])) {
        arr[3] = 'idle'
      } else if (arr[3] !== 'work') {
        arr[3] = 'fault'
      }
      arr[2] = +arr[2].slice(1)
      formated.wxTime = arr[2]
      formated.status = arr[3]
      formated.val = arr[4]
      formated.type = 'STATUS'
    }
  } else if (arr.length === 5) {
    if (['free', 'idle'].includes(arr[3])) {
      arr[3] = 'idle'
    } else if (arr[3] !== 'work') {
      arr[3] = 'fault'
    }
    arr[2] = +arr[2].slice(1)
    formated.wxTime = arr[2]
    formated.status = arr[3]
    formated.val = arr[4]
    formated.type = 'STATUS'
  } else {
    return null
  }
  return formated
}
