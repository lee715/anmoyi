// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['data', 'backbone', 'jquery', 'qrcode', 'views/layer', 'views/login', 'utils'], function(Data, B, $, qr, layerView, loginView, utils) {
    var Router, goto;
    goto = function(route, params) {
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
        'users': function() {
          return goto('users');
        },
        'devicesCreate': function() {
          return goto('devicesCreate');
        },
        'devicesEdit': 'deviceEdit',
        'placesCreate': function() {
          return goto('placesCreate');
        },
        'usersEdit': 'userEdit',
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

      Router.prototype.deviceEdit = function() {
        var data;
        data = utils.query2obj(location.search);
        return goto('devicesEdit', data);
      };

      Router.prototype.userEdit = function() {
        var data;
        data = utils.query2obj(location.search);
        return goto('usersEdit', data);
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
        var query;
        query = location.search.slice(1).split('=')[1];
        return $.ajax({
          url: "/api/ticket?uid=" + query,
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

      return Router;

    })(B.Router);
  });

}).call(this);
