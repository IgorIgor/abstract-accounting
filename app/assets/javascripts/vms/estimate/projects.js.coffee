$ ->
  class self.EstimateProjectsViewModel extends TreeViewModel
    @include TableCommenstHelper

    constructor: (data) ->
      @url = '/estimate/projects/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

      @initializeTableCommentsHelper()

    getType: (o)=>
      "projects"

    namespace: =>
      "estimate"
