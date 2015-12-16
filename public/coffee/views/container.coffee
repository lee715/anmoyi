define [
  'jquery'
  'backbone'
  'views/selector'
], ($, B, SelectorView) ->

  class Container extends B.View

    initialize: (querys) ->
      @_querys = querys
      @render()
      @

    render: (querys) ->
      self = @
      querys or= @_querys
      @$el.empty()
      querys.forEach (query) ->
        self.renderSubView(query)
      @

    renderSubView: (query) ->
      sub = new SelectorView(query)
      @$el.append(sub.el)

