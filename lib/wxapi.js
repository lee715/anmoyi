// Generated by CoffeeScript 1.9.1
(function() {
  var API, MP_API, WXPay, WX_API, _, async, db, redis, wxReply;

  _ = require('lodash');

  db = require('limbo').use('anmoyi');

  WX_API = require('./weixin/api');

  MP_API = require('./weixin/mpApi');

  WXPay = require('weixin-pay');

  async = require('async');

  wxReply = require('./weixin/message');

  redis = require('./services/redis');

  API = (function() {
    "响应微信消息";
    function API() {}

    API.prototype.handleMessage = function(req, callback) {
      var _message;
      _message = req._message;
      console.log('handleMessage', req.body);
      async.waterfall([
        function(next) {
          return WX_API.checkSingle(_message, next);
        }
      ], function(err) {
        return wxReply(_message);
      });
      return callback(null, '');
    };

    API.prototype.handleMessage.route = ['post', '/wx/message'];

    API.prototype.handleMessage.before = [
      function(req, res, next) {
        var key, message, msg, val;
        message = req.body.xml;
        msg = {};
        for (key in message) {
          val = message[key];
          msg[key] = val != null ? val[0] : void 0;
        }
        req._message = msg;
        return next();
      }
    ];

    API.prototype.payTestView = function(req, callback) {
      var openid;
      openid = req.query.openid;
      return WX_API.getPayInfoAsync(openid).then(function(info) {
        return db.place.findOneAsync({
          _id: info._placeId
        }).then(function(place) {
          info.placeName = place.name;
          return info;
        });
      }).then(function(info) {
        var ref;
        info.openid = openid;
        if ((ref = info.status) === 'idle' || ref === 'work') {
          return db.order.createAsync({
            money: info.cost,
            time: info.time,
            openId: openid,
            deviceStatus: info.status,
            uid: info.uid,
            _userId: info._userId,
            _placeId: info._placeId,
            mode: "WX"
          }).then(function(order) {
            console.log("payTestView:getBrandWCPayRequestParamsAsync", openid, "" + order._id, info.cost);
            return WX_API.getBrandWCPayRequestParamsAsync(openid, "" + order._id, info.cost).then(function(args) {
              info.payargs = args;
              info.order = "" + order._id;
              console.log('payTestView:info', info);
              return req.res.render('pay', info);
            });
          });
        } else {
          info.payargs = {};
          return req.res.render('pay', info);
        }
      })["catch"](function() {
        return req.res.send('system error, please try later');
      });
    };

    API.prototype.payTestView.route = ['get', '/view/test/h5pay'];

    API.prototype.orderStatus = function(req, callback) {
      var expect, order;
      order = req.query.order;
      expect = req.query.expect;
      console.log('orderStatus in', order, expect);
      if (!order) {
        return callback(new Error('order is required'));
      }
      return db.order.findOneAsync({
        _id: order
      }).then(function(order) {
        console.log('orderStatus:order', order);
        if (expect && order.status !== expect) {
          return WX_API.queryOrderAsync({
            out_trade_no: "" + order._id
          }).then(function(wx_order) {
            console.log('orderStatus:wxOrder', wx_order);
            if (wx_order.trade_state !== order.status) {
              order.status = wx_order.trade_state;
              if (wx_order.trade_state === 'SUCCESS') {
                order.serviceStatus = "PAIED";
              }
              order.save();
            }
            return wx_order.trade_state;
          });
        } else {
          return order.status;
        }
      }).then(function(status) {
        return callback(null, status);
      })["catch"](function(e) {
        console.log(e);
        return callback(e);
      });
    };

    API.prototype.orderStatus.route = ['get', '/wx/order/status'];

    return API;

  })();

  module.exports = new API;

}).call(this);