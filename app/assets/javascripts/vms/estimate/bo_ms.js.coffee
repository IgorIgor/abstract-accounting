$ ->
  class self.EstimateBomsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/estimate/bo_ms/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

