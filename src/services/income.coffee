redis = require('./redis')
moment = require('moment')
cron = require('cron')
CronJob = require('cron').CronJob
db = require('limbo').use('anmoyi')

DAY_KEY = 'INCOME.DAY.'
WEEK_KEY = 'INCOME.WEEK.'
MONTH_KEY = 'INCOME.MONTH.'

countDay = (uid, income, wxTime) ->
  startDay = moment().startOf('day').toDate().getTime()
  now = moment().toDate().getTime()
  if now - startDay < 1000*60*10
    redis.get "#{DAY_KEY}#{uid}", (err, rt) ->
      unless rt
        rt = []
      else
        rt = JSON.parse(rt)
      rt.push [income, wxTime]
      redis.set "#{DAY_KEY}#{uid}", JSON.stringify(rt), ->

countWeek = (uid, income, wxTime) ->
  start = moment().startOf('week').toDate().getTime()
  now = moment().toDate().getTime()
  if now - start < 1000*60*10
    redis.get "#{WEEK_KEY}#{uid}", (err, rt) ->
      unless rt
        rt = []
      else
        rt = JSON.parse(rt)
      rt.push income
      redis.set "#{WEEK_KEY}#{uid}", JSON.stringify(rt), ->

countMonth = (uid, income, wxTime) ->
  start = moment().startOf('month').toDate().getTime()
  now = moment().toDate().getTime()
  if now - start < 1000*60*10
    redis.get "#{MONTH_KEY}#{uid}", (err, rt) ->
      unless rt
        rt = []
      else
        rt = JSON.parse(rt)
      rt.push income
      redis.set "#{MONTH_KEY}#{uid}", JSON.stringify(rt), ->

clearDay = ->
  db.device.find {}, (err, devices) ->
    if devices
      devices.forEach (device) ->
        uid = device.uid
        redis.get "#{DAY_KEY}#{uid}", (err, rt) ->
          if rt
            rt = JSON.parse(rt)
            len = rt.length
            return if len < 2
            income = (rt[len-1][0] - rt[0][0]) or 0
            wxTime = (rt[len-1][1] - rt[0][1]) or 0
            db.income.create
              _deviceId: device._id
              uid: device.uid
              income: income
              wxTime: wxTime
              type: 'day'
              created: moment().startOf('day').toDate()
            redis.del "#{DAY_KEY}#{uid}"

clearWeek = ->
  db.device.find {}, (err, devices) ->
    if devices
      devices.forEach (device) ->
        uid = device.uid
        redis.get "#{WEEK_KEY}#{uid}", (err, rt) ->
          if rt
            rt = JSON.parse(rt)
            len = rt.length
            return if len < 2
            income = (rt[len-1][0] - rt[0][0]) or 0
            wxTime = (rt[len-1][1] - rt[0][1]) or 0
            db.income.create
              _deviceId: device._id
              uid: device.uid
              income: income
              wxTime: wxTime
              type: 'week'
              created: moment().startOf('week').day('monday').toDate()
            redis.del "#{WEEK_KEY}#{uid}"

clearMonth = ->
  db.device.find {}, (err, devices) ->
    if devices
      devices.forEach (device) ->
        uid = device.uid
        redis.get "#{MONTH_KEY}#{uid}", (err, rt) ->
          if rt
            rt = JSON.parse(rt)
            len = rt.length
            return if len < 2
            income = (rt[len-1][0] - rt[0][0]) or 0
            wxTime = (rt[len-1][1] - rt[0][1]) or 0
            db.income.create
              _deviceId: device._id
              uid: device.uid
              income: income
              wxTime: wxTime
              type: 'month'
              created: moment().startOf('month').toDate()
            redis.del "#{MONTH_KEY}#{uid}", ->

new CronJob '00 00 1 * * *', ->
  clearDay()
, ->
  consol.log('day done')
,true

new CronJob '00 00 1 * * 1', ->
  clearWeek()
, ->
  consol.log('week done')
,true

new CronJob '00 00 1 1 * *', ->
  clearMonth()
, ->
  consol.log('month done')
,true


module.exports = (uid, income, wxTime) ->
  return unless uid
  console.log 'income:', uid, income, wxTime
  countDay(uid, income)
  countWeek(uid, income)
  countMonth(uid, income)

