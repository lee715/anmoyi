// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['data', 'backbone', 'jquery', 'qrcode', 'views/layer', 'views/login', 'utils'], function(Data, B, $, qr, layerView, loginView, utils) {
    var Router, goto;
    goto = function(route, params) {
      Data.handleQuery();
      return Data.checkLogin(route, function() {
        if (Data.layer) {
          return Data.layer.switchTo(route, params);
        } else {
          Data.layer = new layerView({
            'route': route,
            params: params
          });
          return $('body').prepend(Data.layer.el);
        }
      });
    };
    return Router = (function(superClass) {
      extend(Router, superClass);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.initialize = function() {};

      Router.prototype.routes = {
        'login': 'login',
        'devices': function() {
          return goto('devices');
        },
        'orders': function() {
          return goto('orders');
        },
        'places': function() {
          return goto('places');
        },
        'places/detail': function() {
          return goto('placesDetail');
        },
        'users': function() {
          return goto('users');
        },
        'reconciliation': function() {
          return goto('reconciliation');
        },
        'devicesCreate': function() {
          return goto('devicesCreate');
        },
        'devicesEdit': function() {
          return goto('devicesCreate');
        },
        'placesCreate': function() {
          return goto('placesCreate');
        },
        'placesEdit': function() {
          return goto('placesCreate');
        },
        'usersEdit': function() {
          return goto('usersEdit');
        },
        'usersCreate': function() {
          return goto('usersCreate');
        },
        'urlqrcode': 'qrcode',
        'urlauth': 'wx_auth',
        'urlticket': 'wx_ticket',
        '*paramString': 'login'
      };

      Router.prototype.login = function(params) {
        return goto('login');
      };

      Router.prototype.qrcode = function() {
        return $.ajax({
          url: '/api/qrcode',
          method: 'get'
        }).done(function(res, state) {
          var $qr;
          console.log(res);
          $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>');
          $('body').html($qr);
          return $qr.qrcode({
            width: 256,
            height: 256,
            text: res
          });
        });
      };

      Router.prototype.wx_auth = function() {
        return $.ajax({
          url: '/api/auth',
          method: 'get'
        }).done(function(res, state) {
          var $qr;
          console.log(res);
          $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>');
          $('body').html($qr);
          return $qr.qrcode({
            width: 256,
            height: 256,
            text: res
          });
        });
      };

      Router.prototype.wx_ticket = function() {
        var obj, query;
        obj = utils.query2obj(location.search);
        if (obj.uid) {
          query = "uid=" + obj.uid;
        } else if (obj._placeId) {
          query = "_placeId=" + obj._placeId;
        }
        return $.ajax({
          url: "/api/ticket?" + query,
          method: 'get'
        }).done(function(res, state) {
          var $qr;
          $qr = $('<div id="qrcode" style="width:256px;height:256px"></div>');
          $('body').html($qr);
          return $qr.qrcode({
            width: 256,
            height: 256,
            text: res
          });
        });
      };

      return Router;

    })(B.Router);
  });

}).call(this);
