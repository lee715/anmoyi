// Generated by CoffeeScript 1.9.1
(function() {
  module.exports = function(Schema) {
    return new Schema({
      money: Number,
      time: Number,
      status: {
        type: String,
        "default": "PREPAY"
      },
      mode: {
        type: String,
        "default": "TB"
      },
      openId: String,
      uid: String,
      _userId: Schema.Types.ObjectId,
      _placeId: Schema.Types.ObjectId,
      deviceStatus: String,
      serviceStatus: {
        type: String,
        "default": "BEFORE"
      },
      created: {
        type: Date,
        "default": Date.now
      },
      updated: {
        type: Date,
        "default": Date.now
      }
    });
  };

}).call(this);