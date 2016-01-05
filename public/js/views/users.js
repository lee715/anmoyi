// Generated by CoffeeScript 1.9.1
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['jquery', 'backbone', 'collections/users', 'utils', 'text!templates/users.ejs', 'data', 'table'], function($, B, usersCollection, U, usersTemp, Data) {
    var View, columns;
    columns = [
      {
        field: 'name',
        title: '昵称'
      }, {
        field: 'company',
        title: '公司'
      }, {
        field: 'location',
        title: '地址'
      }, {
        field: 'phone',
        title: '电话'
      }, {
        field: 'email',
        title: '邮箱'
      }, {
        field: 'role',
        title: '权限'
      }, {
        field: 'edit',
        title: '操作'
      }
    ];
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.initialize = function() {
        Data.userColl = this.collection = new usersCollection();
        this.render();
        this.fetch();
        return this;
      };

      View.prototype.render = function() {
        this.$el.html(ejs.render(usersTemp));
        this.$table = this.$el.find('#usersTable');
        this.$table.bootstrapTable({
          columns: columns,
          striped: true,
          pagination: true,
          pageSize: 50,
          search: true,
          onClickCell: function(field, val, obj) {
            return Data.app.navigate('/usersEdit?_userId=' + obj._id, {
              trigger: true
            });
          }
        });
        return this;
      };

      View.prototype.fetch = function() {
        var self;
        self = this;
        return this.collection.fetch({
          remove: false,
          success: function(coll, res, opts) {
            return self.renderUsers();
          },
          error: function() {
            return console.log('users.fetch error', arguments);
          }
        });
      };

      View.prototype.renderUsers = function(users) {
        users || (users = this.collection.toJSON());
        return this.$table.bootstrapTable('load', users);
      };

      return View;

    })(B.View);
  });

}).call(this);
