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
      role: '业务员'
      edit: '<a href="javascript:;">编辑</a>'
      password: ''

    initialize: ->

    parse: (data) ->
      data._id = "#{data._id}"
      switch data.role
        when 'place'
          data.roleName = '场地方'
        when 'root'
          data.roleName = '管理员'
        when 'salesman'
          data.roleName = '业务员'
        when 'agent'
          data.roleName = '代理商'
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




