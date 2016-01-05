define [
  'jquery'
  'backbone'
  'collections/users'
  'utils'
  'text!templates/users.ejs'
  'data'
  'table'
], ($, B, usersCollection, U, usersTemp, Data) ->

  columns = [
    field: 'name'
    title: '昵称'
  ,
    field: 'company'
    title: '公司'
  ,
    field: 'location'
    title: '地址'
  ,
    field: 'phone'
    title: '电话'
  ,
    field: 'email'
    title: '邮箱'
  ,
    field: 'role'
    title: '权限'
  ,
    field: 'edit'
    title: '操作'
  ]

  class View extends B.View

    initialize: ->
      Data.userColl = @collection = new usersCollection()
      @render()
      @fetch()
      @


    render: ->
      @$el.html ejs.render(usersTemp)
      @$table = @$el.find('#usersTable')
      @$table.bootstrapTable
        columns: columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) ->
          Data.app.navigate('/usersEdit?_userId='+obj._id,
            trigger: true
          )
      @

    fetch: ->
      self = @
      @collection.fetch
        remove: false
        success: (coll, res, opts) ->
          self.renderUsers()
        error: ->
          console.log 'users.fetch error',arguments

    renderUsers: (users) ->
      users or= @collection.toJSON()
      @$table.bootstrapTable('load', users)

