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
    'distdata': '../bower/distpicker/dist/distpicker.data'
    'dist': '../bower/distpicker/dist/distpicker'
    'essage': '../bower/essage/src/essage'
  shim:
    'bootstrap': ['jquery']
)

require [
  'jquery'
  'bootstrap'
  'backbone'
  './router'
  'data'
  'ejs'
  'distdata'
  'essage'
], (
  $
  bootstrap
  Backbone
  Router
  Data
) ->
  app = Data.app = new Router()
  Backbone.history.start(
    pushState: true
  )
  $.ajax
    method: 'get'
    url: '/api/users/me'
    json: true
  .done (res, state) ->
    console.log res, state
    if res._id
      res._id = "#{res._id}"
      Data.user = res
      Data.home()
    else
      Data.login()
  .fail (res, state, error) ->
    console.log error
    Data.login()

  # Data.app = new Router()
  # Backbone.history.start(
  #   pushState: true
  # )


  # $('#seletorContainer').html(con.el)


