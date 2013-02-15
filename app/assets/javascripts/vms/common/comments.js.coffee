$ ->
  class self.TableCommentsViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @object = object
      @message = ko.observable('')
      @disableSaveComment = ko.computed( =>
        @message() == ''
      )
      @url = TableCommentsViewModel.generateItemsUrl(object)
      super(data)
      @params =
        paginate: true
        page: @page
        per_page: @per_page

    @generateItemsUrl: (object) =>
      params =
        item_id: object.id
        item_type: object.type
      "/comments.json?#{$.param(params)}"

    saveComment: =>
      params =
        paginate: true
        comment:
          item_id: @object.id
          item_type: @object.type
          message: @message()
      $.ajax(
        type: 'post'
        url: 'comments'
        data: params
        complete: (data) =>
          if data.responseText == 'success'
            @message('')
            $.getJSON(@url, params, (data) =>
              @object.subitems(@createChildrenViewModel(data, params, @object))
              @object.comments_count(data.count)
            )
      )

    createChildrenViewModel: (data, params, object) =>
      new TableCommentsViewModel(data, params, object)


  self.TableCommenstHelper =
    initializeTableCommentsHelper: ->
      for object in @documents()
        object.comments_count = ko.observable(object.comments_count)

    generateChildrenParams: (object)->
      {paginate: true, item_id: object.id, item_type: object.type}

    generateItemsUrl: (object) ->
      TableCommentsViewModel.generateItemsUrl(object)

    onDataReceived: (data) ->
      for object in data.objects
        object.comments_count = ko.observable(object.comments_count)
      @.__proto__.__proto__.onDataReceived(data)

    createChildrenViewModel: (data, params, object) ->
      new TableCommentsViewModel(data, params, object)
