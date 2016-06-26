config     = require('config')
express    = require('express')
bodyParser = require('body-parser')
errSrv     = require('./services/err')
Promise = require('bluebird')
# redis = require('./services/redis')
mejs           = require('mejs')
require './services/limbo'
db = require('limbo').use('anmoyi')
redis = require('./services/redis')
U = require('./services/util')
Promise.promisifyAll(redis)
Promise.promisifyAll(db)
WX_API = require('./weixin/api')
session   = require('cookie-session')

app = express()

app.set 'view', mejs.initView("public/templates/*.ejs")
app.use(express.static('public'))
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use express.query()
app.use require('express-xml-bodyparser')()
app.use require('cookie-parser')()
app.use session(config.sessionConfig)
app.use require('./services/user').init

# app.use '/wx/notify', WX_API.useWXCallback (msg, req, res, next) ->
#   db.order.updateAsync
#     _id: msg.out_trade_no
#   ,
#     status: "SUCCESS"
#     serviceStatus: "PAIED"
#   ,
#     upsert: false
#     new: false
#   .then ->
#     res.success()

app.get '/api/test', (req, res, next) ->
  console.log('send', req.query)
  res.send('ok')

require('./router')(app, require('./api'), [], '/api')
apis = require('./apis')
Object.keys(apis).forEach (key) ->
  require('./router')(app, apis[key], [], '/api')
require('./router')(app, require('./wxapi'), [])
require('./services/socket')
require('./weixin/mpApi').setupMpTicket (err) ->
  console.log(err) if err
require('./weixin/api').createMenu()

# app.get '/wx/message', (req, res, next) ->
#   {timestamp, nonce, signature, echostr} = req.query
#   token = 'anmoyi'
#   arr = [timestamp, nonce, token]
#   arr.sort()
#   tmpStr = U.sha1(arr.join(''))
#   if tmpStr is signature
#     res.send(echostr)
#   else
#     res.send(echostr)

app.get '*', (req, res, next) ->
  res.render('index')

app.listen config.PORT
console.log "Listen on #{config.PORT}"

