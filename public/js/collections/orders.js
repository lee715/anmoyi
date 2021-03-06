// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['backbone', 'underscore', 'jquery', 'data', 'models/order'], function(B, _, $, Data, model) {
    var Colection;
    return Colection = (function(superClass) {
      extend(Colection, superClass);

      function Colection() {
        return Colection.__super__.constructor.apply(this, arguments);
      }

      Colection.prototype.model = model;

      Colection.prototype.url = '/api/orders';

      Colection.prototype.initialize = function() {
        return this.on('add', function(model, collection) {
          return Data.models[model.id] = model;
        });
      };

      Colection.prototype.fetch = function(opts) {
        return $.ajax({
          url: '/api/orders',
          data: opts.data,
          method: 'GET',
          json: true
        }).done((function(_this) {
          return function(data, state) {
            if (state === 'success') {
              _this.add(data);
              return opts.success && opts.success(_this, data);
            } else {
              return opts.error && opts.error(data, state);
            }
          };
        })(this));
      };

      return Colection;

    })(B.Collection);
  });

}).call(this);
