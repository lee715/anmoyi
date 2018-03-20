const crypto = require('crypto')

function sha1 (str) {
  return crypto.createHash('sha1').update(str, 'ascii').digest('base64')
}

function getDate () {
  let d = new Date
  return `${d.getMonth()}${d.getDate()}${d.getHours()}${Math.ceil(d.getMinutes()/5)*5}`
}

function sign () {
  let mid = 'DCJHSG'
  let date = getDate()
  let time = 10
  let money = 89
  let random = 789
  let str = (mid + date + time + money + random).toLowerCase()
  console.log(str)
  let sign = sha1(str).replace(/[^A-Za-z0-9]+/g, '')
  rt = sign.slice(-6).split('').map((s) => s.charCodeAt()%9).join('')
  return rt
}

console.log(sign())