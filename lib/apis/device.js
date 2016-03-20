// Generated by CoffeeScript 1.10.0
(function() {
  var API, Promise, _, canEdit, createValidator, db, deviceJson, moment, needCreate, pluck, sockSrv, u, userSrv;

  _ = require('lodash');

  db = require('limbo').use('anmoyi');

  u = require('../services/util');

  userSrv = require('../services/user');

  sockSrv = require('../services/socket');

  moment = require('moment');

  Promise = require('bluebird');

  pluck = function(keys) {
    return function(arr) {
      var rt;
      rt = [];
      arr.forEach(function(item) {
        return rt.push(_.pick(item, keys));
      });
      return rt;
    };
  };

  deviceJson = ['_id', 'lastUsed', 'uid', '_userId', 'created', 'updated', 'place', 'location', 'price', 'status', 'discount', 'remission', 'income'];

  createValidator = {
    _placeId: "ObjectId",
    price: "Number",
    time: "Number",
    discount: "Number",
    remission: "Number",
    uid: "String:required",
    name: "String:required",
    _userId: "ObjectId:required",
    type: "String"
  };

  needCreate = Object.keys(createValidator);

  canEdit = needCreate;

  API = (function() {
    function API() {}

    API.prototype.createDevice = function(req, callback) {
      var _placeId, params;
      params = _.pick(req.body, needCreate);
      if (params.type === 'pulse') {
        params.time = 1;
      }
      _placeId = req.body._placeId;
      if (!params.uid) {
        return req.res.status(302).send('paramErr');
      }
      return db.place.findOneAsync({
        _id: _placeId
      }).then(function(place) {
        params._userId = place._agentId;
        return db.device.createAsync(params);
      }).then(function(device) {
        return callback(null, device);
      })["catch"](function(e) {
        return callback(e);
      });
    };

    API.prototype.createDevice.route = ['post', '/devices'];

    API.prototype.createDevice.before = [userSrv.isRoot];

    API.prototype.createDevice.validator = createValidator;

    API.prototype.editDevice = function(req, callback) {
      var _id, data;
      _id = req.body._id;
      if (!req.body.uid) {
        return req.res.status(302).send('paramErr');
      }
      data = _.pick(req.body, canEdit);
      return db.device.update({
        _id: _id
      }, data, callback);
    };

    API.prototype.editDevice.route = ['put', '/devices'];

    API.prototype.editDevice.validator = {
      _id: "ObjectId:required",
      $or: {
        _placeId: "ObjectId",
        price: "Number",
        time: "Number",
        discount: "Number",
        remission: "Number",
        name: "String",
        _userId: "ObjectId"
      }
    };

    API.prototype.delDevice = function(req, callback) {
      var _id;
      _id = req.body._id;
      return db.device.remove({
        _id: _id
      }, callback);
    };

    API.prototype.delDevice.route = ['delete', '/devices'];

    API.prototype.order = function(req, callback) {
      var order, ref, uid;
      ref = req.query, uid = ref.uid, order = ref.order;
      return sockSrv.start(uid, 10, function(err) {
        if (err) {
          return callback(err);
        }
        return db.device.update({
          uid: uid
        }, {
          status: 'work'
        }, {
          upsert: false,
          "new": false
        }, function(err, rt) {
          console.log(err, rt);
          return callback(err, 'ok');
        });
      });
    };

    API.prototype.order.route = ['get', '/devices/order'];

    API.prototype.order.before = [userSrv.isRoot];

    API.prototype.fetchDevices = function(req, callback) {
      var _placeId, cons, role, user;
      user = req._data.user;
      role = user.role;
      _placeId = req.query._placeId;
      if (role === 'root') {
        cons = {};
      } else {
        cons = {
          _userId: user._id
        };
      }
      if (_placeId) {
        cons._placeId = _placeId;
      }
      return db.device.findAsync(cons).then(function(devices) {
        var map, placeids, userids;
        map = {};
        userids = [];
        placeids = [];
        devices.forEach(function(device) {
          device.status = device.realStatus;
          if (device._userId) {
            userids.push("" + device._userId);
          }
          if (device._placeId) {
            return placeids.push("" + device._placeId);
          }
        });
        return db.user.findAsync({
          _id: {
            $in: _.uniq(userids)
          }
        }).then(function(users) {
          users.forEach(function(user) {
            return map["" + user._id] = user.name;
          });
          return devices.map(function(device) {
            device = device.toJSON();
            device.user = map["" + device._userId];
            return device;
          });
        }).then(function(devices) {
          return db.place.findAsync({
            _id: {
              $in: _.uniq(placeids)
            }
          }).then(function(places) {
            places.forEach(function(place) {
              return map["" + place._id] = place;
            });
            return devices.map(function(device) {
              var ref, ref1;
              device.location = (ref = map["" + device._placeId]) != null ? ref.location : void 0;
              device.place = (ref1 = map["" + device._placeId]) != null ? ref1.name : void 0;
              return device;
            });
          });
        });
      }).map(function(device) {
        var now, today, yestoday;
        if (_placeId) {
          now = new Date;
          today = moment().startOf('day').toDate();
          yestoday = moment().add(-1, 'day').startOf('day').toDate();
          device.total = {};
          return Promise.map([[now, today], [today, yestoday]], function(arg) {
            var from, to;
            to = arg[0], from = arg[1];
            return db.order.findAsync({
              created: {
                $gt: from,
                $lt: to
              },
              uid: device.uid,
              status: 'SUCCESS',
              serviceStatus: {
                $in: ['STARTED', 'ENDED']
              }
            }).then(function(orders) {
              var total;
              total = {};
              orders.forEach(function(order) {
                if (!total[order.mode]) {
                  total[order.mode] = 0;
                }
                return total[order.mode] += order.money;
              });
              return total;
            });
          }).then(function(totals) {
            device.total.today = totals[0];
            device.total.yestoday = totals[1];
            return device;
          });
        } else {
          return device;
        }
      }).then(function(devices) {
        return callback(null, devices);
      })["catch"](function(e) {
        return console.log(e.stack);
      });
    };

    API.prototype.fetchDevices.route = ['get', '/devices'];

    API.prototype.fetchDevices.before = [userSrv.isAgent];

    return API;

  })();

  module.exports = new API;

}).call(this);