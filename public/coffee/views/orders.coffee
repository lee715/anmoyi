define [
  'jquery'
  'backbone'
  'collections/orders'
  'utils'
  'views/container'
  'views/confirm'
  'views/timepicker'
  'text!templates/orders.ejs'
  'data'
  'table'
], ($, B, ordersCollection, U, ContainerView, ConfirmView, TimeView, ordersTemp, Data) ->

  columns = [
    field: '_id'
    title: '订单号'
  ,
    field: 'status'
    title: '订单状态'
  ,
    field: 'serviceStatus'
    title: '服务状态'
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
    field: 'deviceName'
    title: '设备名称'
  ,
    field: 'placeName'
    title: '场地方'
  ,
    field: 'agentName'
    title: '代理商'
  ,
    field: 'created'
    title: '日期'
  ,
    field: 'refund'
    title: '退款'
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
      timeView = new TimeView()
      @$el.prepend(timeView.render().el)
      @$table = @$el.find('#ordersTable')
      @$container = @$el.find('#seletorContainer')
      @$table.bootstrapTable
        columns: columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) =>
          # Data.app.navigate('/devicesEdit?id='+obj._id,
          #   trigger: true
          # )
          if field is 'refund'
            view = new ConfirmView(
              title: '退款确认'
              content: "是否确认退还该订单款项（人民币#{obj.money}元）？"
              btns:
                confirm: '确认'
                cancel: '取消'
              onConfirm: =>
                @refund(obj)
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)

      timeView.on('submit', (data) =>
        @fetch(data)
      )
      @

    renderOrders: (orders) ->
      orders or= @collection.toJSON()
      @$table.bootstrapTable('load', orders)

    refund: (order) ->
      self = @
      $.ajax({
        url: "/api/wx/refund?_orderId=#{order._id}"
        json: true
      })
      .done((res) =>
        if res.code or res.msg
          Essage.show
            message: '退款失败: ' + res.msg
            status: 'error'
          , 2000
        else
          Essage.show
            message: '退款成功'
            status: 'success'
          , 2000
      )
      .fail((err)->
        Essage.show
          message: '退款失败'
          status: 'error'
        , 2000
      )

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

    fetch: (opts) ->
      self = @
      @collection.fetch
        data: opts
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


