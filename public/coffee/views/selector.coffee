define [
  'backbone'
  'text!templates/selector.ejs'
  'ejs'
], (B, temp) ->

  class Seletor extends B.View

    className: "btn-group"

    events:
      'click .selector': 'onSelect'

    initialize: (options) ->
      @_data = options.data
      @name = options.name
      @id = options.id
      @render()

    render: ->
      @$el.html ejs.render(temp,
        name: @name
        data: @_data
        id: @id
      )
      @$btn = @$el.find('.btn-val')

    onSelect: (e) ->
      val = $(e.target).html()
      if val is 'all'
        val = @name
      @$btn.text val

