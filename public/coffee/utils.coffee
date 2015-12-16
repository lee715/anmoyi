define [
  'jquery'
  'underscore'
], ($, _) ->

  U =

    cutLoc: (loc) ->
      rt = []
      ls = loc.split('-')
      len = ls.length
      for i in [1..len]
        rt.push ls.slice(0, i).join('-')
      return rt

    formData: ($e) ->
      data = {}
      $e.find('[name]').each ->
        name = $(this).attr('name')
        val = $(this).val()
        data[name] = val
      return data

    query2obj: (query) ->
      query = query.replace(/^\?/, '')
      obj = {}
      arr = query.split('&')
      arr.forEach (item) ->
        pics = item.split('=')
        obj[pics[0]] = pics[1]
      return obj