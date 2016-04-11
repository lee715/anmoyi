// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['jquery', 'backbone', 'views/selector'], function($, B, SelectorView) {
    var Container;
    return Container = (function(superClass) {
      extend(Container, superClass);

      function Container() {
        return Container.__super__.constructor.apply(this, arguments);
      }

      Container.prototype.initialize = function(querys) {
        this._querys = querys;
        this.render();
        return this;
      };

      Container.prototype.render = function(querys) {
        var self;
        self = this;
        querys || (querys = this._querys);
        this.$el.empty();
        querys.forEach(function(query) {
          return self.renderSubView(query);
        });
        return this;
      };

      Container.prototype.renderSubView = function(query) {
        var sub;
        sub = new SelectorView(query);
        return this.$el.append(sub.el);
      };

      return Container;

    })(B.View);
  });

}).call(this);
