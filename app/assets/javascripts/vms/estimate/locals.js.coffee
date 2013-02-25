$ ->
  class self.EstimateLocalsViewModel extends TreeViewModel
    @include TableCommenstHelper

    constructor: (data, params = {}) ->
      @url = '/estimate/locals/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
      @params.project_id = params.project_id if params.project_id?

      @initializeTableCommentsHelper()

    cancel: (obj)=>
      $.ajax(
        type: 'GET'
        url:  "/estimate/locals/#{obj.id}/cancel"
        data: {}
        complete: (data) =>
          response = JSON.parse(data.responseText)
          if response['result'] == 'success'
            @getPaginateData()
      )

    getType: (o)=>
      "locals"

    namespace: =>
      "estimate"
