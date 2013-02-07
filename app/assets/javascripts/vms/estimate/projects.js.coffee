$ ->
  class self.EstimateProjectsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/estimate/projects/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

    getType: (o)=>
      "projects"

    namespace: =>
      "estimate"
