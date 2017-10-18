define [
  'jquery'
  'backbone'
  'collections/places'
  'utils'
  'views/container'
  'views/confirm'
  'text!templates/places.ejs'
  'data'
  'table'
], ($, B, Collection, U, ContainerView, ConfirmView, temp, Data) ->

  columns = [
    field: 'name'
    title: '场地方'
    sortable: true
  ,
    field: 'address'
    title: '地理位置'
    sortable: true
  ,
    field: 'deviceStatus'
    title: '设备状态(正常/总数)'
    sortable: true
  ,
    field: 'today'
    title: '今日流水'
    sortable: true
  ,
    field: 'yestoday'
    title: '昨日流水'
    sortable: true
  ,
    field: 'thisWeek'
    title: '本周流水'
    sortable: true
  ,
    field: 'lastWeek'
    title: '上周流水'
    sortable: true
  ,
    field: 'deviceStatus'
    title: '设备状态(正常/总数)'
    sortable: true
  ,
    field: 'reconciliation'
    title: '对账'
  ]

  root_columms = [
    field: 'edit'
    title: '编辑'
  ,
    field: 'delete'
    title: '删除'
  ]

  class View extends B.View

    initialize: ->
      @_filter = {}
      @collection = new Collection()
      @columns = columns.slice()
      if Data.isRoot()
        @columns = @columns.concat(root_columms)
      @render()
      @fetch()
      @

    events:
      'click .selector': 'onSelect'

    render: ->
      @$el.html ejs.render(temp, {isDetail: false})
      @$table = @$el.find('#placesTable')
      @$container = @$el.find('#seletorContainer')
      @$table.bootstrapTable
        columns: @columns
        striped: true
        pagination: true
        pageSize: 50
        search: true
        onClickCell: (field, val, obj) ->
          if field is 'deviceStatus'
            Data.app.navigate('/devices?_placeId='+obj._id,
              trigger: true
            )
          else if field is 'reconciliation'
            Data.app.navigate('/reconciliation?_placeId='+obj._id,
              trigger: true
            )
          else if field is 'edit'
            Data.app.navigate('/placesEdit?_placeId='+obj._id,
              trigger: true
            )
          else if field is 'delete'
            view = new ConfirmView(
              title: '删除确认'
              content: '是否确认删除该场地?'
              onConfirm: ->
                Data.del('place', obj._id)
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)

      @

    renderPlaces: (places) ->
      places or= @collection.models.map((place) ->
        return place.parse(place.toJSON())
      )
      @$table.bootstrapTable('load', places)

    fetch: ->
      self = @
      $.ajax({
        url: '/api/places/statistic'
        json: true
      })
      .done((places) =>
        @collection.add(places)
        @renderPlaces()
      )
      .fail((err)->
        console.log(err)
      )

    onSelect: (e) ->
      $target = $(e.target)
      id = $target.data('id')
      val = $target.html()
      f = {}
      f[id] = val
      @filter f
