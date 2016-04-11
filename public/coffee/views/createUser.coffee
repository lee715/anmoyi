define [
  'backbone'
  'underscore'
  'views/confirm'
  'text!templates/createUser.ejs'
  'text!templates/alert.ejs'
  'utils'
  'data'
  'ejs'
], (B, _, ConfirmView, temp, alert, utils, Data) ->

  defaultVals =
    name: ''
    company: ''
    email: ''
    phone: ''
    role: 'salesman'
    mailAddress: ''
    qq: ''
    bankName: ''
    bankAccount: ''
    contacts: [{}, {}]
    license: ''
    roles: ['agent', 'server']
    password: ''

  class View extends B.View

    initialize: (opts) ->
      opts or= {}
      @type = opts.type or 'create'
      id = Data.query._userId
      if id
        @type = 'edit'
        @model = Data.models[id]
        unless @model
          return Data.home()
      else if @type is 'edit'
        @model = Data.user
      @render()

    events:
      'submit form': 'onSubmit'
      'change select[name="role"]': 'refreshAddition'

    render: ->
      self = @
      data = {}
      if @type is 'edit' and @model
        data = @model.toJSON()
      data = _.extend({}, defaultVals, data)
      data.type = @type
      self.$el.html ejs.render(temp, data)
      @$addition = @$el.find('#createUserAddition')
      @

    showAlert: (state, err) ->
      switch @type
        when 'create'
          if state is 'success'
            msg = '创建成功，你可以继续创建'
          else
            msg = '创建失败，请检查表单'
        when 'edit'
          if state is 'success'
            msg = '编辑成功!'
          else
            msg = '编辑失败，请检查参数'
      Essage.show
        message: msg
        status: state
      , 2000

    onSubmit: (e) ->
      e.preventDefault()
      self = @
      data = utils.formData($(e.target))
      data.contacts = [
        name: data.contacts_name
        phone: data.contacts_phone
      ,
        name: data.contacts_name_bk
        phone: data.contacts_phone_bk
      ]
      $.ajax
        url: '/api/users'
        data: data
        json: true
        method: if @type is 'edit' then 'put' else 'post'
      .done (res, state) ->
        if state is 'success'
          self.render()
          if self.type is 'create'
            view = new ConfirmView(
              title: '用户创建'
              content: '用户创建成功，用户密码为 ' + res.password + '。请妥善保存。'
              btns:
                confirm: '回到用户列表'
                cancel: '继续创建'
              onConfirm: ->
                Data.route('/users')
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)
          else
            # self.showAlert(state)
            view = new ConfirmView(
              title: '用户编辑'
              content: '用户编辑成功。'
              btns:
                confirm: '回到用户列表'
                cancel: '继续编辑'
              onConfirm: ->
                Data.route('/users')
                view.close()
              onCancel: ->
                view.close()
            )
            $('body').append(view.$el)
        else
          self.showAlert(state)
      return false

    refreshAddition: (e) ->
      val = $(e.target).val()
      if val is 'agent'
        @$addition.removeClass('hide')
      else
        if @type is 'create'
          @$addition.find('input').val('')
        @$addition.addClass('hide')

    showPass: (pass) ->
      @$el.find("form").prepend("<p>密码是："+pass+"</p>")

