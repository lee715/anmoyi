// Generated by CoffeeScript 1.9.1
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['backbone', 'underscore', 'jquery'], function(B, _, $) {
    var Model;
    return Model = (function(superClass) {
      extend(Model, superClass);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.defaults = {
        price: 10,
        time: 8,
        discount: 100,
        remission: 0,
        uid: '',
        locs: null,
        _userId: null,
        _placeId: null,
        section: 0,
        edit: '<a href="javascript:;">编辑</a>',
        start: '<a href="javascript:;">开机</a>',
        "delete": '<a href="javascript:;">删除</a>'
      };

      Model.prototype.initialize = function() {};

      Model.prototype.parse = function(data) {
        var ref;
        data._id = "" + data._id;
        data._userId = "" + data._userId;
        if (data.status === 'fault') {
          data.colorStatus = '<span style="color:#ff3c00;">' + data.status + '</span>';
        } else {
          data.colorStatus = data.status;
        }
        data.locs = ((ref = data.location) != null ? ref.split('-') : void 0) || null;
        return data;
      };

      Model.prototype.idAttribute = 'uid';

      Model.prototype.update = function(params) {
        return $.ajax({
          url: "/devices/" + this.id,
          method: 'put',
          data: params
        }).done(function(res, state) {
          if (state === 'success') {
            res.uid = "res.uid";
            return this.set(res);
          }
        });
      };

      return Model;

    })(B.Model);
  });

}).call(this);