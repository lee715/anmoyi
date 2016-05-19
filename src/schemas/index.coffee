
module.exports = (Schema) ->
  Device: require('./device')(Schema)
  User: require('./user')(Schema)
  Order: require('./order')(Schema)
  Status: require('./status')(Schema)
  Alien: require('./alien')(Schema)
  Place: require('./place')(Schema)