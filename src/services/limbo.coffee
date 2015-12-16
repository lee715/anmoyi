config   = require('config')
fs       = require('fs')
mongoose = require('mongoose')
limbo    = require('limbo')

connOptions = {}
if config.MONGO_AUTH_DB
  connOptions.auth = {authdb: config.MONGO_AUTH_DB}

if config.MONGO_USE_CERT
  connOptions.replset = {
    sslCA: fs.readFileSync(config.MONGO_CA_PATH)
    sslCert: fs.readFileSync(config.MONGO_CLIENT_CRT_PATH)
    sslKey: fs.readFileSync(config.MONGO_CLIENT_KEY_PATH)
  }

limboPort = config.LIMBO?.port or Number(config.PORT) + 50
limbo.use 'anmoyi',
  conn: mongoose.createConnection(config.DB_URL, connOptions)
  schemas: require('../schemas')(mongoose.Schema)
