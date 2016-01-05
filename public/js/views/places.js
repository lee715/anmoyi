// Generated by CoffeeScript 1.9.1
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['jquery', 'backbone', 'collections/places', 'utils', 'views/container', 'text!templates/places.ejs', 'data', 'table'], function($, B, Collection, U, ContainerView, temp, Data) {
    var View, columns;
    columns = [
      {
        field: 'name',
        title: '场地方',
        sortable: true
      }, {
        field: 'address',
        title: '地理位置',
        sortable: true
      }, {
        field: 'deviceStatus',
        title: '设备状态(正常/总数)',
        sortable: true
      }, {
        field: 'reconciliation',
        title: '对账'
      }, {
        field: 'today',
        title: '今日流水'
      }, {
        field: 'yestoday',
        title: '昨日流水'
      }, {
        field: 'thisWeek',
        title: '本周流水'
      }, {
        field: 'lastWeek',
        title: '上周流水'
      }, {
        field: 'thisMonth',
        title: '本月流水'
      }, {
        field: 'lastMonth',
        title: '上月流水'
      }, {
        field: 'edit',
        title: '编辑'
      }, {
        field: 'delete',
        title: '删除'
      }, {
        field: 'section',
        title: '区间'
      }
    ];
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.initialize = function() {
        this._filter = {};
        Data.placeColl = this.collection = new Collection();
        this.collection.on('change:section', (function(_this) {
          return function() {
            return _this.renderPlaces();
          };
        })(this));
        this.render();
        this.fetch();
        return this;
      };

      View.prototype.events = {
        'click .selector': 'onSelect',
        'submit #timeForm': 'querySection'
      };

      View.prototype.render = function() {
        this.$el.html(ejs.render(temp));
        this.$table = this.$el.find('#placesTable');
        this.$container = this.$el.find('#seletorContainer');
        this.$table.bootstrapTable({
          columns: columns,
          striped: true,
          pagination: true,
          pageSize: 50,
          search: true,
          onClickCell: function(field, val, obj) {
            if (field === 'deviceStatus') {
              return Data.app.navigate('/devices?_placeId=' + obj._id, {
                trigger: true
              });
            } else if (field === 'reconciliation') {
              return Data.app.navigate('/reconciliation?_placeId=' + obj._id, {
                trigger: true
              });
            } else if (field === 'edit') {
              return Data.app.navigate('/placesEdit?_placeId=obj._id', {
                trigger: true
              });
            } else if (field === 'delete') {
              return Data.del('place', obj._id);
            }
          }
        });
        return this;
      };

      View.prototype.renderPlaces = function(places) {
        places || (places = this.collection.toJSON());
        return this.$table.bootstrapTable('load', places);
      };

      View.prototype.fetch = function() {
        var self;
        self = this;
        return this.collection.fetch({
          remove: false,
          success: function(coll, res, opts) {
            return self.renderPlaces();
          },
          error: function() {
            return console.log(arguments);
          }
        });
      };

      View.prototype.onSelect = function(e) {
        var $target, f, id, val;
        $target = $(e.target);
        id = $target.data('id');
        val = $target.html();
        f = {};
        f[id] = val;
        return this.filter(f);
      };

      View.prototype.querySection = function(e) {
        var data, self;
        e.preventDefault();
        self = this;
        data = U.formData($(e.target));
        data.startDate = new Date(data.startDate);
        data.endDate = new Date(data.endDate);
        return this.collection.querySection(data);
      };

      return View;

    })(B.View);
  });

}).call(this);