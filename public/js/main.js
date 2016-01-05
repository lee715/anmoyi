// Generated by CoffeeScript 1.9.1
(function() {
  require.config({
    paths: {
      'jquery': '../bower/jquery/dist/jquery',
      'bootstrap': '../bower/bootstrap/dist/js/bootstrap',
      'table': '../bower/bootstrap-table/dist/bootstrap-table',
      'underscore': '../bower/underscore/underscore',
      'templates': '../templates',
      'backbone': '../bower/backbone/backbone',
      'ejs': '../bower/ejs/ejs',
      'text': '../bower/text/text',
      'views': './views',
      'models': './models',
      'collections': './collections',
      'data': './data',
      'utils': './utils',
      'qrcode': '../bower/jquery-qrcode/jquery.qrcode.min',
      'distdata': '../bower/distpicker/dist/distpicker.data',
      'datepicker': '../bower/bootstrap-datepicker/dist/js/bootstrap-datepicker.min',
      'dist': '../bower/distpicker/dist/distpicker',
      'essage': '../bower/essage/src/essage'
    },
    shim: {
      'bootstrap': ['jquery']
    }
  });

  require(['jquery', 'bootstrap', 'backbone', './router', 'data', 'ejs', 'distdata', 'essage', 'datepicker'], function($, bootstrap, Backbone, Router, Data) {
    var app;
    app = Data.app = new Router();
    return $.ajax({
      method: 'get',
      url: '/api/users/me',
      json: true
    }).done(function(res, state) {
      console.log(res, state);
      if (res._id) {
        res._id = "" + res._id;
        Data.user = res;
        return Backbone.history.start({
          pushState: true
        });
      } else {
        Backbone.history.start({
          pushState: true
        });
        return Data.login();
      }
    }).fail(function(res, state, error) {
      console.log(error);
      Backbone.history.start({
        pushState: true
      });
      return Data.login();
    });
  });

}).call(this);
