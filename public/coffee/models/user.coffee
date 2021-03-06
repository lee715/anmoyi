define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      name: ''
      location: ''
      phone: ''
      email: ''
      company: ''
      mailAddress: ''
      contacts: [{}, {}]
      license: ''
      qq: ''
      bankName: ''
      bankAccount: ''
      role: 'salesman'
      edit: '<a href="javascript:;">Edit</a>'
      password: ''

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data

    idAttribute: '_id'

    update: (params) ->
      $.ajax(
        url: "/users/#{@id}"
        method: 'put'
        data: params
      ).done((res, state) =>
        if state is 'success'
          @set(res)
      )

    getById: (_id) ->
      $.ajax(
        url: "/agents/#{_id}"
        method: 'get'
      ).done((res, state) ->
        if state is 'success'
          @set(res)
      )




