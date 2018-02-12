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
        province: '',
        city: '',
        district: '',
        phone: '',
        email: '',
        company: '',
        mailAddress: '',
        qq: '',
        price: '',
        time: '',
        bankName: '',
        bankAccount: '',
        _salesmanId: '',
        _agentId: '',
        section: 0,
        discount: 100,
        remission: 0,
        contacts: [{}, {}],
        p: 100,
        moneys: [0, 0, 0, 0, 0, 0],
        device: {
          total: 0,
          normal: 0
        },
        edit: '<a href="javascript:;">编辑</a>',
        "delete": '<a href="javascript:;">删除</a>',
        reconciliation: '<a href="javascript:;">对账</a>'
      };

      Model.prototype.initialize = function() {};

      Model.prototype.parse = function(data) {
        var normal, total;
        data._id = "" + data._id;
        data.address = data.province + "-" + data.city + "-" + data.district;
        normal = data.device.normal;
        total = data.device.total;
        if (normal === total) {
          data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#259b24;'>" + normal + "/" + total + "</a>";
        } else if (normal === 0) {
          data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#ff3c00;'>" + normal + "/" + total + "</a>";
        } else {
          data.deviceStatus = "<a href='javascript:;' class='route' data-url='/devices' style='color:#ff9800;'>" + normal + "/" + total + "</a>";
        }
        data.today = data.moneys[0].toFixed(2);
        data.yestoday = data.moneys[1].toFixed(2);
        data.thisWeek = data.moneys[2].toFixed(2);
        data.lastWeek = data.moneys[3].toFixed(2);
        return data;
      };

      Model.prototype.idAttribute = '_id';

      Model.prototype.update = function(params) {
        return $.ajax({
          url: "/places/" + this.id,
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
