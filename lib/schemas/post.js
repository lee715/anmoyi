// Generated by CoffeeScript 1.9.1
(function() {
  var _, xss;

  _ = require('lodash');

  xss = require('xss');

  module.exports = function(Schema, options) {
    var AttachmentSchema, LinkSchema, PostSchema;
    LinkSchema = new Schema({
      url: String,
      shortUrl: String,
      type: String,
      title: String,
      created: {
        type: Date,
        "default": Date.now
      }
    });
    AttachmentSchema = new Schema({
      _objectId: {
        type: Schema.Types.ObjectId,
        ref: 'Work'
      },
      objectType: String
    });
    return PostSchema = new Schema({
      title: {
        es_indexed: true,
        es_analyzer: 'ik',
        type: String,
        "default": '',
        get: function(val) {
          if (val != null) {
            return xss(val);
          } else {
            return val;
          }
        }
      },
      content: {
        es_indexed: true,
        es_analyzer: 'ik_smart',
        type: String,
        "default": '',
        get: function(val) {
          if ((val != null) && this.postMode === 'html') {
            return xss(val, {
              whiteList: _.assign(xss.whiteList, {
                strike: [],
                td: ['width', 'colspan', 'rowspan', 'align', 'valign'],
                a: ['rel', 'target', 'href', 'title']
              })
            });
          } else {
            return val;
          }
        }
      },
      code: String,
      links: [LinkSchema],
      attachments: [AttachmentSchema],
      isDeleted: {
        es_indexed: true,
        type: Boolean,
        "default": false
      },
      created: {
        es_indexed: true,
        type: Date,
        "default": Date.now
      },
      updated: {
        es_indexed: true,
        type: Date,
        "default": Date.now
      },
      _creatorId: {
        type: Schema.Types.ObjectId,
        ref: 'User'
      },
      involveMembers: [
        {
          es_indexed: true,
          type: Schema.Types.ObjectId,
          ref: 'User'
        }
      ],
      _projectId: {
        es_indexed: true,
        type: Schema.Types.ObjectId,
        ref: 'Project'
      },
      _organizationId: {
        type: Schema.Types.ObjectId,
        ref: 'Organization'
      },
      postMode: String,
      type: {
        type: String,
        "default": 'text'
      },
      pin: {
        type: Boolean,
        "default": false
      },
      isArchived: {
        es_indexed: true,
        type: String,
        "default": null
      },
      visiable: {
        es_indexed: true,
        es_index: 'not_analyzed',
        type: String,
        "default": 'all'
      },
      tagIds: [
        {
          type: Schema.Types.ObjectId,
          ref: 'Tag'
        }
      ]
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
  };

}).call(this);