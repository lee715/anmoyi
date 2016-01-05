// Generated by CoffeeScript 1.9.1
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['backbone', 'underscore', 'text!templates/createUser.ejs', 'text!templates/alert.ejs', 'utils', 'data', 'ejs'], function(B, _, temp, alert, utils, Data) {
    var View, defaultVals;
    defaultVals = {
      name: '',
      company: '',
      email: '',
      phone: '',
      role: 'salesman',
      mailAddress: '',
      qq: '',
      bankName: '',
      bankAccount: '',
      contacts: [{}, {}],
      license: '',
      roles: ['agent', 'salesman', 'admin']
    };
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.initialize = function(opts) {
        var id;
        opts || (opts = {});
        this.type = opts.type || 'create';
        id = Data.query._userId;
        if (id) {
          this.type = 'edit';
          this.model = Data.models[id];
          if (!this.model) {
            return Data.home();
          }
        }
        return this.render();
      };

      View.prototype.events = {
        'submit form': 'onSubmit',
        'change select[name="role"]': 'refreshAddition'
      };

      View.prototype.render = function() {
        var data, self;
        self = this;
        data = {};
        if (this.type === 'edit' && this.model) {
          data = this.model.toJSON();
        }
        data = _.extend({}, defaultVals, data);
        data.type = this.type;
        self.$el.html(ejs.render(temp, data));
        this.$addition = this.$el.find('#createUserAddition');
        return this;
      };

      View.prototype.showAlert = function(state, err) {
        var msg;
        switch (this.type) {
          case 'create':
            if (state === 'success') {
              msg = '创建成功，你可以继续创建';
            } else {
              msg = '创建失败，请检查表单';
            }
            break;
          case 'edit':
            if (state === 'success') {
              msg = '编辑成功!';
            } else {
              msg = '编辑失败，请检查参数';
            }
        }
        return Essage.show({
          message: msg,
          status: state
        }, 2000);
      };

      View.prototype.onSubmit = function(e) {
        var data, self;
        e.preventDefault();
        self = this;
        data = utils.formData($(e.target));
        data.contacts = [
          {
            name: data.contacts_name,
            phone: data.contacts_phone
          }, {
            name: data.contacts_name_bk,
            phone: data.contacts_phone_bk
          }
        ];
        $.ajax({
          url: '/api/users',
          data: data,
          json: true,
          method: this.type === 'edit' ? 'put' : 'post'
        }).done(function(res, state) {
          if (state === 'success') {
            self.render();
            self.showAlert(state);
            if (self.type === 'create') {
              return self.showPass(res.password);
            }
          }
        });
        return false;
      };

      View.prototype.refreshAddition = function(e) {
        var val;
        val = $(e.target).val();
        if (val === 'agent') {
          return this.$addition.removeClass('hide');
        } else {
          if (this.type === 'create') {
            this.$addition.find('input').val('');
          }
          return this.$addition.addClass('hide');
        }
      };

      View.prototype.showPass = function(pass) {
        return this.$el.find("form").prepend("<p>密码是：" + pass + "</p>");
      };

      return View;

    })(B.View);
  });

}).call(this);