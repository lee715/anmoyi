// Generated by CoffeeScript 1.9.1
(function() {
  var xss;

  xss = require('xss');

  module.exports = function(Schema) {
    var OrgSchema;
    OrgSchema = new Schema({
      openId: String,
      _creatorId: {
        type: Schema.Types.ObjectId,
        ref: 'User'
      },
      name: {
        type: String,
        get: function(val) {
          if (val != null) {
            return xss(val);
          } else {
            return val;
          }
        }
      },
      logo: String,
      cover: String,
      location: String,
      category: String,
      description: {
        type: String,
        get: function(val) {
          if (val != null) {
            return xss(val);
          } else {
            return val;
          }
        }
      },
      website: {
        type: String,
        get: function(val) {
          if (val != null) {
            return xss(val);
          } else {
            return val;
          }
        }
      },
      background: {
        type: String,
        get: function(val) {
          if (val != null) {
            return xss(val);
          } else {
            return val;
          }
        }
      },
      isDeleted: {
        type: Boolean,
        "default": false
      },
      created: {
        type: Date,
        "default": Date.now
      },
      updated: {
        type: Date,
        "default": Date.now
      },
      prefs: {
        type: Schema.Types.Mixed,
        get: function(val) {
          if (val) {
            return val;
          } else {
            return {};
          }
        },
        set: function(val) {
          if (val) {
            return val;
          } else {
            return {};
          }
        }
      },
      py: String,
      pinyin: String,
      projectIds: Array,
      dividers: {
        type: String,
        get: function(val) {
          if (val) {
            return JSON.parse(val);
          } else {
            return [];
          }
        },
        set: function(val) {
          if (val) {
            return JSON.stringify(val);
          } else {
            return val;
          }
        }
      },
      isPublic: {
        type: Boolean,
        "default": false
      }
    }, {
      read: 'secondaryPreferred',
      toObject: {
        virtuals: true,
        getters: true
      },
      toJSON: {
        virtuals: true,
        getters: true
      }
    });
    return OrgSchema;
  };

}).call(this);