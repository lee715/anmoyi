define [
  'jquery'
  'backbone'
  'collections/orders'
  'utils'
  'views/container'
  'text!templates/orders.ejs'
  'data'
  'table'
], ($, B, ordersCollection, U, ContainerView, ordersTemp, Data) ->

  columns = [
    field: '_id'
    title: '订单号'
  ,
    field: 'status'
    title: '订单状态'
  ,
    field: 'money'
    title: '订单金额'
  ,
    field: 'time'
    title: '服务时长'
  ,
    field: 'mode_zh'
    title: '支付模式'
  ,
    field: 'username'
    title: '用户'
  ,
    field: 'uid'
    title: '设备编号'
  ,
    field: '_userId'
    title: '代理商'
  ,
    field: 'created'
    title: '日期'
  ]

  class View extends B.View

    initialize: ->
      @_filter = {}
      Data.orderColl = @collection = new ordersCollection()
      @render()
      @fetch()
      @

    events:
      'click .selector': 'onSelect'

    render: ->
      @$el.html ejs.render(ordersTemp)
      @$table = @$el.find('#ordersTable')
      @$container = @$el.find('#seletorContainer')
      @$table.bootstrapTable
        columns: columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) ->
          # Data.app.navigate('/devicesEdit?id='+obj._id,
          #   trigger: true
          # )
      @

    renderOrders: (orders) ->
      orders or= @collection.toJSON()
      @$table.bootstrapTable('load', orders)

    # renderQuerys: ->
    #   if @containerView
    #     @$container.html(@containerView.render(@_querys).el)
    #   else
    #     @containerView = sub = new ContainerView(@_querys)
    #     @$container.html(sub.el)

    # refreshQuerys: (devices) ->
    #   devices or= @collection.toJSON()
    #   @_querys = []
    #   data =
    #     locations: {}
    #     places: {}
    #     users: {}
    #     status: {}
    #   devices.forEach (device) ->
    #     locs = U.cutLoc(device.location)
    #     locs.forEach (loc) ->
    #       data.locations[loc] or= 0
    #       data.locations[loc]++
    #     data.places[device.place] or= 0
    #     data.places[device.place]++
    #     data.users[device.user] or= 0
    #     data.users[device.user]++
    #     data.status[device.status] or= 0
    #     data.status[device.status]++
    #   for key, val of data
    #     if key is 'users' and Object.keys(val).length is 1
    #       @hideUser()
    #     @_querys.push
    #       id: idMap[key]
    #       name: locales[key]
    #       data: Object.keys(val)
    #   @renderQuerys()

    fetch: ->
      self = @
      @collection.fetch
        remove: false
        success: (coll, res, opts) ->
          # self.refreshQuerys()
          self.renderOrders()
        error: ->
          console.log arguments

    # filter: (options) ->
    #   _f = _.extend @_filter, options
    #   Object.keys(options).forEach (key) ->
    #     if _f[key] is 'all'
    #       delete _f[key]
    #   devices = _.filter @collection.toJSON(), (device) ->
    #     for key, val of _f
    #       if key is 'location'
    #         unless ~device[key].indexOf(val)
    #           return false
    #       else if device[key] isnt val
    #         return false
    #     return true
      # @renderQuerys(devices)
      # @renderOrders(orders)

    onSelect: (e) ->
      $target = $(e.target)
      id = $target.data('id')
      val = $target.html()
      f = {}
      f[id] = val
      @filter f


