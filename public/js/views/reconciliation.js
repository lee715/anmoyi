// Generated by CoffeeScript 1.12.7
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['backbone', 'underscore', 'text!templates/reconciliation.ejs', 'models/user', 'models/place', 'utils', 'data', 'ejs', 'table'], function(B, _, temp, userModel, placeModel, utils, Data) {
    var View, columns;
    columns = [
      {
        field: 'month',
        title: '月份'
      }, {
        field: 'total',
        title: '总金额'
      }, {
        field: 'wxFee',
        title: '微信手续费'
      }, {
        field: 'placeFee',
        title: '分成金额'
      }, {
        field: 'salesFee',
        title: '业务员分成'
      }, {
        field: 'count',
        title: '实际所得'
      }
    ];
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.initialize = function() {
        return this.render();
      };

      View.prototype.render = function() {
        var self;
        self = this;
        this.fetch(function(err, data) {
          var map, month, tableData, year, year1, year2;
          month = (new Date).getMonth() + 1;
          year = year1 = year2 = (new Date).getFullYear();
          map = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
          if (month === 1) {
            year1 = year - 1;
          }
          if (month <= 2) {
            year2 = year - 1;
          }
          data.months = [year + "年" + month + "月", year1 + "年" + map[(month + 11) % 12] + "月", year2 + "年" + map[(month + 10) % 12] + "月"];
          tableData = [];
          data.totals.forEach((function(_this) {
            return function(one, i) {
              var rt;
              rt = {};
              rt.month = data.months[i];
              rt.total = one;
              rt.wxFee = (one * 0.06).toFixed(2);
              if (data.place.agentMode === 'percent') {
                rt.agentFee = (rt.wxFee * data.place.agentCount / 100).toFixed(2);
              } else {
                rt.agentFee = data.place.agentCount;
              }
              if (data.place.salesmanMode === 'percent') {
                rt.salesFee = (rt.agentFee * data.place.salesmanCount / 100).toFixed(2);
              } else {
                rt.salesFee = data.place.salesmanCount;
              }
              rt.count = rt.agentFee - rt.salesFee;
              return tableData.push(rt);
            };
          })(this));
          tableData.push(_.reduce(tableData, function(a, b) {
            return a + b;
          }));
          self.$el.html(ejs.render(temp, data));
          this.$table = this.$el.find('#recTable');
          this.$table.bootstrapTable({
            columns: columns,
            striped: true,
            pagination: true,
            pageSize: 50
          });
          return this.$table.bootstrapTable('load', tableData);
        });
        return this;
      };

      View.prototype.showAlert = function(state, err) {
        var note;
        if (state === 'success') {
          return Data.app.navigate('/devices');
        } else {
          note = err || '登陆失败，请检查';
          return Essage.show({
            message: note,
            status: 'error'
          });
        }
      };

      View.prototype.fetch = function(callback) {
        var user;
        user = Data.user.toJSON();
        if (user.role === 'agent') {
          return this.fetchPlace((function(_this) {
            return function(err, place) {
              return _this.fetchTotals(function(err, totals) {
                var data;
                data = {
                  agent: user,
                  place: place,
                  totals: totals
                };
                return callback(null, data);
              });
            };
          })(this));
        } else if (user.role === 'place') {
          return this.fetchAgent(user._agentId, (function(_this) {
            return function(err, agent) {
              return _this.fetchTotals(function(err, totals) {
                var data;
                data = {
                  agent: agent,
                  place: user,
                  totals: totals
                };
                return callback(null, data);
              });
            };
          })(this));
        } else if (user.role === 'root') {
          return this.fetchPlace((function(_this) {
            return function(err, place) {
              return _this.fetchAgent(place._agentId, function(err, agent) {
                return _this.fetchTotals(function(err, totals) {
                  var data;
                  data = {
                    agent: agent,
                    place: place,
                    totals: totals
                  };
                  return callback(null, data);
                });
              });
            };
          })(this));
        }
      };

      View.prototype.fetchAgent = function(_agentId, callback) {
        return $.ajax({
          url: "/api/agents/" + _agentId,
          json: true
        }).done(function(res, state) {
          var model;
          if (state === 'success') {
            model = new userModel(res);
            return callback(null, model.toJSON());
          }
        });
      };

      View.prototype.fetchPlace = function(callback) {
        return $.ajax({
          url: "/api/places/" + (Data.getPlaceId()),
          json: true
        }).done(function(res, state) {
          var model;
          if (state === 'success') {
            model = new placeModel(res);
            return callback(null, model.toJSON());
          }
        });
      };

      View.prototype.fetchTotals = function(callback) {
        return $.ajax({
          url: "/api/reconciliation/" + (Data.getPlaceId()),
          json: true
        }).done(function(res, state) {
          if (state === 'success') {
            return callback(null, res);
          }
        });
      };

      return View;

    })(B.View);
  });

}).call(this);
