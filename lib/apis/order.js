// Generated by CoffeeScript 1.9.1
(function() {
  var API, _, db, moment, u, userSrv;

  _ = require('lodash');

  db = require('limbo').use('anmoyi');

  u = require('../services/util');

  userSrv = require('../services/user');

  moment = require('moment');

  API = (function() {
    function API() {}

    API.prototype.getOrders = function(req, callback) {
      var cons, endDate, startDate, user;
      user = req._data.user;
      startDate = req.query.startDate;
      endDate = req.query.endDate;
      if (user.role === 'root') {
        cons = {};
      } else {
        cons = {
          _userId: user._id
        };
      }
      if (startDate || endDate) {
        cons.created = {};
        if (startDate) {
          cons.created.$gt = startDate;
        }
        if (endDate) {
          cons.created.$lt = endDate;
        }
      }
      return db.order.findAsync(cons).then(function(orders) {
        var alienMap, openIds;
        alienMap = {};
        openIds = _.pluck(orders, 'openId');
        return db.alien.findAsync({
          openId: {
            $in: openIds
          }
        }).then(function(aliens) {
          aliens.forEach(function(alien) {
            return alienMap[alien.openId] = alien;
          });
          orders = orders.map(function(order) {
            order = order.toJSON();
            order.username = alienMap[order.openId].name;
            return order;
          });
          return orders;
        });
      }).then(function(orders) {
        var agentMap, ids;
        agentMap = {};
        ids = _.pluck(orders, '_agentId');
        return db.user.findAsync({
          _id: {
            $in: ids
          }
        }).then(function(users) {
          users.forEach(function(user) {
            return agentMap[user._id] = user;
          });
          orders = orders.map(function(order) {
            var ref;
            order.agentName = (ref = agentMap["" + order._agentId]) != null ? ref.name : void 0;
            return order;
          });
          orders = _.sortByOrder(orders, ['created'], ['desc']);
          return callback(null, orders);
        });
      })["catch"](function(e) {
        console.log(e);
        return callback(new Error('systemErr'));
      });
    };

    API.prototype.getOrders.route = ['get', '/orders'];

    API.prototype.getOrders.before = [userSrv.isAgent];

    API.prototype.section = function(req, callback) {
      var _placeId, cons, endDate, ref, startDate, type, user;
      user = req._data.user;
      ref = req.query, startDate = ref.startDate, endDate = ref.endDate, type = ref.type, _placeId = ref._placeId;
      cons = {};
      if (type === 'place') {
        if (user.role === 'agent') {
          cons._agentId = user._id;
        }
      } else if (type === 'device') {
        cons._placeId = _placeId;
      }
      return db[type].findAsync(cons).then(function(data) {
        var ids, match, uids;
        ids = _.pluck(data, '_id');
        match = {
          status: 'SUCCESS'
        };
        if (type === 'place') {
          match._placeId = {
            $in: ids
          };
        } else {
          uids = _.pluck(data, 'uid');
          match.uid = {
            $in: uids
          };
        }
        if (startDate || endDate) {
          match.created = {};
          if (startDate) {
            match.created.$gt = moment(startDate).startOf('day');
          }
          if (endDate) {
            match.created.$lt = moment(endDate).endOf('day');
          }
        }
        return db.order.findAsync(match);
      }).then(function(orders) {
        var totals;
        totals = {};
        orders.forEach(function(order) {
          var key;
          if (type === 'place') {
            key = "" + order._placeId;
          } else {
            key = "" + order.uid;
          }
          if (!totals[key]) {
            totals[key] = 0;
          }
          return totals[key] += order.money;
        });
        return callback(null, totals);
      });
    };

    API.prototype.section.route = ['get', '/section'];

    API.prototype.section.before = API.prototype.getOrders.before = [userSrv.isAgent];

    return API;

  })();

  module.exports = new API;

}).call(this);