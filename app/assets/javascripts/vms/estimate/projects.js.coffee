$ ->
  class self.EstimateProjectsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/estimate/projects/data.json'

      super(data)

      for object in @documents()
        object.comments_count = ko.observable(object.comments_count)

      @params =
        page: @page
        per_page: @per_page

    getType: (o)=>
      "projects"

    namespace: =>
      "estimate"

    receiveComments: (object) =>
      if object.subitems() == null
        params =
          paginate: true
          item_id: object.id
          item_type: object.type
        $.getJSON(ProjectsCommentsViewModel.generateItemsUrl(object), params, (data) =>
          object.subitems(@createChildrenViewModel(data, params, object))
        )
      else
        object.subitems(null)

    onDataReceived: (data) =>
      for object in data.objects
        object.comments_count = ko.observable(object.comments_count)
      super(data)

    createChildrenViewModel: (data, params, object) =>
      new ProjectsCommentsViewModel(data, params, object)


  class self.ProjectsCommentsViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @object = object
      @message = ko.observable('')
      @disableSaveComment = ko.computed( =>
        @message() == ''
      )
      @url = ProjectsCommentsViewModel.generateItemsUrl(object)
      super(data)
      @params =
        page: @page
        per_page: @per_page

    @generateItemsUrl: (object) =>
      params =
        item_id: object.id
        item_type: object.type
      "/comments.json?#{$.param(params)}"

    saveComment: (object) =>
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
      new ProjectsCommentsViewModel(data, params, object)
