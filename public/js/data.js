// Generated by CoffeeScript 1.10.0
(function() {
  define([], function() {
    var Data;
    window.data = Data = {
      models: {},
      dontHandle: function() {
        return /^\/url/.test(location.pathname);
      },
      checkLogin: function(route, cb) {
        if (route === 'login') {
          return cb();
        } else if (this.user) {
          return cb();
        } else {
          return this.login();
        }
      },
      home: function() {
        var role, url;
        if (this.dontHandle()) {
          return;
        }
        if (this.user) {
          role = this.user.role;
          url = role === 'place' ? '/reconciliation' : '/devices';
          return this.app.navigate(url, {
            trigger: true
          });
        } else {
          return this.login();
        }
      },
      login: function() {
        if (this.dontHandle()) {
          return;
        }
        return this.app.navigate('/login', {
          trigger: true
        });
      },
      route: function(url) {
        console.log('Data.route', url);
        return this.app.navigate(url, {
          trigger: true
        });
      },
      isRoot: function() {
        return this.user.role === 9;
      }
    };
    return Data;
  });

}).call(this);
