// Generated by CoffeeScript 1.9.1
(function() {
  var config, connOptions, fs, limbo, limboPort, mongoose, ref;

  config = require('config');

  fs = require('fs');

  mongoose = require('mongoose');

  limbo = require('limbo');

  connOptions = {};

  if (config.MONGO_AUTH_DB) {
    connOptions.auth = {
      authdb: config.MONGO_AUTH_DB
    };
  }

  if (config.MONGO_USE_CERT) {
    connOptions.replset = {
      sslCA: fs.readFileSync(config.MONGO_CA_PATH),
      sslCert: fs.readFileSync(config.MONGO_CLIENT_CRT_PATH),
      sslKey: fs.readFileSync(config.MONGO_CLIENT_KEY_PATH)
    };
  }

  limboPort = ((ref = config.LIMBO) != null ? ref.port : void 0) || Number(config.PORT) + 50;

  limbo.use('anmoyi', {
    conn: mongoose.createConnection(config.DB_URL, connOptions),
    schemas: require('../schemas')(mongoose.Schema)
  });

}).call(this);