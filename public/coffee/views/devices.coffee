define [
  'jquery'
  'backbone'
  'collections/devices'
  'utils'
  'views/container'
  'text!templates/devices.ejs'
  'data'
  'table'
], ($, B, devicesCollection, U, ContainerView, devicesTemp, Data) ->

  locales =
    locs: '按地址筛选'
    locations: '按地址筛选'
    places: '按场地筛选'
    users: '按商家筛选'
    status: '按设备状态筛选'

  idMap =
    locs: 'location'
    locations: 'location'
    places: 'place'
    users: 'user'
    status: 'status'

  columns = [
    field: 'uid'
    title: '编号'
  ,
    field: 'user'
    title: '商家'
  ,
    field: 'location'
    title: '地址'
  ,
    field: 'place'
    title: '场所'
  ,
    field: 'status'
    title: '状态'
  ,
    field: 'price'
    title: '价格'
  ,
    field: 'remission'
    title: '优惠'
  ,
    field: 'discount'
    title: '费率'
  ,
    field: 'income'
    title: '收入'
  ,
    field: 'edit'
    title: '操作'
  ]

  class View extends B.View

    initialize: ->
      @_filter = {}
      Data.deviceColl = @collection = new devicesCollection()
      @render()
      @fetch()
      @

    events:
      'click .selector': 'onSelect'

    render: ->
      @$el.html ejs.render(devicesTemp)
      @$table = @$el.find('#devicesTable')
      @$container = @$el.find('#seletorContainer')
      @$table.bootstrapTable
        columns: columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) ->
          Data.app.navigate('/devicesEdit?id='+obj._id,
            trigger: true
          )
      @

    renderDevices: (devices) ->
      devices or= @collection.toJSON()
      @$table.bootstrapTable('load', devices)

    renderQuerys: ->
      if @containerView
        @$container.html(@containerView.render(@_querys).el)
      else
        @containerView = sub = new ContainerView(@_querys)
        @$container.html(sub.el)

    hideUser: ->
      @$table.bootstrapTable('hideColumn', 'user')

    refreshQuerys: (devices) ->
      devices or= @collection.toJSON()
      @_querys = []
      data =
        locations: {}
        places: {}
        users: {}
        status: {}
      devices.forEach (device) ->
        locs = U.cutLoc(device.location)
        locs.forEach (loc) ->
          data.locations[loc] or= 0
          data.locations[loc]++
        data.places[device.place] or= 0
        data.places[device.place]++
        data.users[device.user] or= 0
        data.users[device.user]++
        data.status[device.status] or= 0
        data.status[device.status]++
      for key, val of data
        if key is 'users' and Object.keys(val).length is 1
          @hideUser()
        @_querys.push
          id: idMap[key]
          name: locales[key]
          data: Object.keys(val)
      @renderQuerys()

    fetch: ->
      self = @
      @collection.fetch
        remove: false
        success: (coll, res, opts) ->
          self.refreshQuerys()
          self.renderDevices()
        error: ->
          console.log arguments

    filter: (options) ->
      _f = _.extend @_filter, options
      Object.keys(options).forEach (key) ->
        if _f[key] is 'all'
          delete _f[key]
      devices = _.filter @collection.toJSON(), (device) ->
        for key, val of _f
          if key is 'location'
            unless ~device[key].indexOf(val)
              return false
          else if device[key] isnt val
            return false
        return true
      # @renderQuerys(devices)
      @renderDevices(devices)

    onSelect: (e) ->
      $target = $(e.target)
      id = $target.data('id')
      val = $target.html()
      f = {}
      f[id] = val
      @filter f


