// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['jquery', 'backbone', 'data', 'text!templates/layer.ejs', 'views/devices', 'views/users', 'views/places', 'views/createDevice', 'views/createUser', 'views/createPlace', 'views/reconciliation', 'views/login', 'views/orders'], function($, B, Data, layerTemp, devicesView, usersView, placesView, createDeviceView, createUserView, createPlaceView, reconciliationView, loginView, ordersView) {
    var Layer, formatDate;
    formatDate = function(time) {
      var d, hh, m, mm, now, ss, y;
      now = new Date(time);
      y = now.getFullYear();
      m = now.getMonth() + 1;
      d = now.getDate();
      hh = now.getHours();
      mm = now.getMinutes();
      ss = now.getSeconds();
      return y + "/" + m + "/" + d + " " + hh + ":" + mm + ":" + ss;
    };
    return Layer = (function(superClass) {
      extend(Layer, superClass);

      function Layer() {
        return Layer.__super__.constructor.apply(this, arguments);
      }

      Layer.prototype.initialize = function(options) {
        this.options = options || {};
        this.params = this.options.params;
        this._route = this.options.route;
        this._views = {};
        this.render();
        return this;
      };

      Layer.prototype.events = {
        'click .route': 'routeHdl'
      };

      Layer.prototype.routeHdl = function(e) {
        var url;
        url = $(e.target).data('url');
        return Data.route(url);
      };

      Layer.prototype.render = function() {
        var ref, ref1, ref2, ref3;
        this.$el.html(ejs.render(layerTemp, {
          isLogin: !!Data.user,
          isRoot: ((ref = Data.user) != null ? ref.get('role') : void 0) === 'root',
          isAgent: ((ref1 = Data.user) != null ? ref1.get('role') : void 0) === 'agent',
          isServer: ((ref2 = Data.user) != null ? ref2.get('role') : void 0) === 'server',
          isPlace: ((ref3 = Data.user) != null ? ref3.get('role') : void 0) === 'place'
        }));
        this.$main = this.$el.find('#mainSection');
        this.$nav = this.$el.find('.navbar-header');
        this.renderSubView();
        if (this.t) {
          clearInterval(this.t);
        }
        if (Data.user) {
          this.renderTime();
        }
        return this;
      };

      Layer.prototype.switchTo = function(route, params) {
        this.params = params;
        this._route = route;
        return this.render();
      };

      Layer.prototype.renderTime = function() {
        var time;
        time = Data.user.get('now') || Date.now();
        this.$nav.append('<span style="line-height:50px;" id="locale_time">' + formatDate(time) + '</span>');
        return this.t = setInterval(function() {
          time += 1000;
          return $('#locale_time').html(formatDate(time));
        }, 1000);
      };

      Layer.prototype.renderSubView = function() {
        switch (this._route) {
          case 'devices':
            return this._views.devices = new devicesView({
              el: this.$main[0]
            });
          case 'places':
            return this._views.places = new placesView({
              el: this.$main[0]
            });
          case 'orders':
            return this._views.orders = new ordersView({
              el: this.$main[0]
            });
          case 'users':
            return this._views.users = new usersView({
              el: this.$main[0]
            });
          case 'reconciliation':
            return this._views.reconciliation = new reconciliationView({
              el: this.$main[0]
            });
          case 'devicesCreate':
            return this._views.createDevice = new createDeviceView({
              el: this.$main[0]
            });
          case 'usersCreate':
            return this._views.createUser = new createUserView({
              el: this.$main[0]
            });
          case 'placesCreate':
            return this._views.createPlace = new createPlaceView({
              el: this.$main[0]
            });
          case 'login':
            return this._views.login = new loginView({
              el: this.$main[0]
            });
          case 'devicesEdit':
            return this._views.editDevice = new createDeviceView({
              el: this.$main[0],
              params: this.params,
              type: 'edit'
            });
          case 'usersEdit':
            return this._views.editUser = new createUserView({
              el: this.$main[0],
              params: this.params,
              type: 'edit'
            });
        }
      };

      return Layer;

    })(B.View);
  });

}).call(this);
