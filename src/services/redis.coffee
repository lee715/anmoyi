redis   = require('redis')
config  = require('config')

{server, port} = config.REDIS_CONFIG
module.exports = redis.createClient(port, server)