// Generated by CoffeeScript 1.10.0
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
        name: '',
        location: '',
        phone: '',
        email: '',
        company: '',
        role: 0,
        edit: '<a href="javascript:;">Edit</a>'
      };

      Model.prototype.initialize = function() {};

      Model.prototype.parse = function(data) {
        data._id = "" + data._id;
        return data;
      };

      Model.prototype.idAttribute = '_id';

      Model.prototype.update = function(params) {
        return $.ajax({
          url: "/users/" + this.id,
          method: 'put',
          data: params
        }).done(function(res, state) {
          if (state === 'success') {
            return this.set(res);
          }
        });
      };

      return Model;

    })(B.Model);
  });

}).call(this);
