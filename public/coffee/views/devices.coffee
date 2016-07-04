define [
  'jquery'
  'backbone'
  'collections/devices'
  'collections/places'
  'utils'
  'views/container'
  'views/confirm'
  'text!templates/devices.ejs'
  'data'
  'table'
], ($, B, devicesCollection, placesCollection, U, ContainerView, confirmView, devicesTemp, Data) ->

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
    field: 'name'
    title: '名称'
    sortable: true
  ,
    field: 'colorStatus'
    title: '状态'
    sortable: true
  ,
    field: 'income'
    title: '收入'
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
    field: 'start'
    title: '开机'
  ]

  root_columns = [
    field: 'edit'
    title: '编辑'
  ,
    field: 'delete'
    title: '删除'
  ]

  class View extends B.View

    initialize: ->
      @_filter = {}
      opts = {}
      @_placeId = opts._placeId = Data.query._placeId
      Data.deviceColl = @collection = new devicesCollection([], opts)
      @collection.on('change:section', => @renderDevices())
      @columns = columns.slice()
      if Data.isRoot()
        @columns = @columns.concat(root_columns)
      if @_placeId
        @columns = @columns.slice(0, 3).concat([{field: 'today', title: '今日流水'}, {field: 'yestoday', title: '昨日流水'}], @columns.slice(3), [{field: 'section', title: '区间'}])
      @render()
      @fetch()
      @

    events:
      'click .selector': 'onSelect'
      'submit #timeForm': 'querySection'

    render: ->
      @$el.html ejs.render(devicesTemp, _placeId: @_placeId)
      @$table = @$el.find('#devicesTable')
      @$container = @$el.find('#seletorContainer')
      @$table.bootstrapTable
        columns: @columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) ->
          if field is 'edit'
            Data.app.navigate('/devicesEdit?uid='+obj.uid,
              trigger: true
            )
          else if field is 'delete'
            view = new confirmView(
              title: '删除确认'
              content: '是否确认删除该设备?'
              onConfirm: ->
                Data.del('device', obj._id)
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)
          else if field is 'start'
            id = '' + Date.now()
            console.log(id, "开机<input id=\"#{id}\" type=\"text\" value=\"10\" />分钟?")
            view = new confirmView(
              title: '开机确认'
              content: "开机<input style=\"margin:0 10px 0 10px;width:60px\" id=\"#{id}\" type=\"text\" value=\"10\" />分钟?"
              onConfirm: ->
                time = $('#' + id).val()
                Data.order('start', obj.uid, time)
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)

      @

    renderPlace: ->
      _placeId = Data.getPlaceId()
      return unless _placeId
      (new placesCollection).getOne(_placeId, (err, place) =>
        place = place.parse(place.toJSON())
        @$el.prepend('<span style="margin-bottom:10px">场地方: <a class="route" href="javascript:;" data-url="/places">'+place.name+'</a></span><span style="margin-bottom:10px;margin-left:20px">地理位置:'+place.address+'</span>')
      )
      models = @collection.toJSON()
      todayTotal = _.reduce _.pluck(models, 'today'), (a, b) ->
        [tb1, wx1] = a.split('/')
        [tb2, wx2] = b.split('/')
        return  (+tb1 + +tb2) + '/' + (+wx1 + +wx2)
      yestodayTotal = _.reduce _.pluck(models, 'yestoday'), (a, b) ->
        [tb1, wx1] = a.split('/')
        [tb2, wx2] = b.split('/')
        return  (+tb1 + +tb2) + '/' + (+wx1 + +wx2)
      @$el.append("<span>今日流水总计: #{todayTotal}</span><span style='margin-left:10px'>昨日流水总计: #{yestodayTotal}</span>")

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
        return unless device.location
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
          self.renderPlace()
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

    querySection: (e) ->
      e.preventDefault()
      self = @
      data = U.formData($(e.target))
      data.startDate = new Date(data.startDate)
      data.endDate = new Date(data.endDate)
      data._placeId = @_placeId
      @collection.querySection(data)


