// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['backbone', 'underscore', 'text!templates/createUser.ejs', 'text!templates/alert.ejs', 'utils', 'data', 'ejs'], function(B, _, temp, alert, utils, Data) {
    var View, defaultVals, urlMap;
    urlMap = {
      create: '/api/users/create',
      edit: '/api/users/edit'
    };
    defaultVals = {
      name: '',
      company: '',
      email: '',
      phone: '',
      location: '',
      role: 0
    };
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.initialize = function(opts) {
        var id, ref;
        opts || (opts = {});
        this.type = opts.type || 'create';
        id = (ref = opts.params) != null ? ref.id : void 0;
        if (id) {
          this.model = Data.models[id];
        }
        return this.render();
      };

      View.prototype.events = {
        'submit form': 'onSubmit'
      };

      View.prototype.render = function() {
        var data, self;
        self = this;
        data = {};
        if (this.type === 'edit' && this.model) {
          data = this.model.toJSON();
        }
        return self.$el.html(ejs.render(temp, _.extend({}, defaultVals, data)));
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
        $.ajax({
          url: urlMap[this.type],
          data: data,
          json: true,
          method: this.type === 'edit' ? 'put' : 'post'
        }).done(function(res, state) {
          if (state === 'success') {
            self.render();
            return self.showAlert(state);
          }
        });
        return false;
      };

      return View;

    })(B.View);
  });

}).call(this);
