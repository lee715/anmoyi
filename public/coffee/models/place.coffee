define [
  'backbone'
  'underscore'
  'jquery'
], (B, _, $) ->

  class Model extends B.Model

    defaults:
      name: ''
      location: ''
      province: ''
      city: ''
      district: ''
      phone: ''
      email: ''
      company: ''
      mailAddress: ''
      qq: ''
      bankName: ''
      bankAccount: ''
      _salesmanId: ''
      _agentId: ''
      contacts: [{}, {}]
      edit: '<a href="javascript:;">Edit</a>'

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      data.address = "#{data.province}-#{data.city}-#{data.district}"
      data

    idAttribute: '_id'

    update: (params) ->
      $.ajax(
        url: "/places/#{@id}"
        method: 'put'
        data: params
      ).done((res, state) ->
        if state is 'success'
          @set(res)
      )




