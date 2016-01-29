require.config(
  paths:
    'jquery': '../bower/jquery/dist/jquery'
    'bootstrap': '../bower/bootstrap/dist/js/bootstrap'
    'table': '../bower/bootstrap-table/dist/bootstrap-table'
    'underscore': '../bower/underscore/underscore'
    'templates': '../templates'
    'backbone': '../bower/backbone/backbone'
    'ejs': '../bower/ejs/ejs'
    'text': '../bower/text/text'
    'views': './views'
    'models': './models'
    'collections': './collections'
    'data': './data'
    'utils': './utils'
    'qrcode': '../bower/jquery-qrcode/jquery.qrcode.min'
    'ChineseDistricts': '../bower/distpicker/dist/distpicker.data'
    'datepicker': '../bower/bootstrap-datepicker/dist/js/bootstrap-datepicker.min'
    'dist': '../bower/distpicker/dist/distpicker'
    'essage': '../bower/essage/src/essage'
  shim:
    'bootstrap': ['jquery']
    'qrcode': ['jquery']
)

require [
  'jquery'
  'bootstrap'
  'backbone'
  './router'
  'data'
  'ejs'
  'ChineseDistricts'
  'essage'
  'datepicker'
], (
  $
  bootstrap
  Backbone
  Router
  Data
) ->
  app = Data.app = new Router()

  $.ajax
    method: 'get'
    url: '/api/users/me'
    json: true
  .done (res, state) ->
    if res._id
      res._id = "#{res._id}"
      Data.storeUser(res)
      Backbone.history.start(
        pushState: true
      )
    else
      Backbone.history.start(
        pushState: true
      )
      Data.login()
  .fail (res, state, error) ->
    console.log error
    Backbone.history.start(
      pushState: true
    )
    Data.login()

  # Data.app = new Router()
  # Backbone.history.start(
  #   pushState: true
  # )


  # $('#seletorContainer').html(con.el)


