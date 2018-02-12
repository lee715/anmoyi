_ = require('lodash')
qrcodeConf = require('config').wxConfig
uuid = require('uuid')
crypto = require('crypto')

U =
  v1: ->
    uuid.v1().replace(/-/g, '')

  v4: ->
    uuid.v4().replace(/-/g, '')

  md5: (str) ->
    md5sum = crypto.createHash('md5')
    md5sum.update str
    str = md5sum.digest 'hex'
    return str

  sha1: (str) ->
    return crypto.createHash('sha1').update(str).digest('hex')

  qsParseSortByAscii: (data) ->
    keys = Object.keys(data)
    keys.sort()
    arr = []
    keys.forEach (key) ->
      if data[key]
        arr.push "#{key}=#{data[key]}"
    return arr.join('&')

  json2xml: (obj) ->
    str = "<xml>"
    Object.keys(obj).forEach (key) ->
      str += "<#{key}>#{obj[key]}</#{key}>"
    str += "</xml>"
    return str

  isDate: (str) ->
    return !!(new Date(str)).getTime()

  randomString: (len) ->
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
    ret = ''
    while (len > 0) {
      rand = Math.floor(Math.random() * 0x100000000)
      for (i = 26; i > 0 && len > 0; i -= 6, len--) {
        ret += chars[0x3F & rand >>> i]
      }
    }
    return ret
    
module.exports = U