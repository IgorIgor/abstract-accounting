$ ->
  class self.EstimateBomsViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/estimate/bo_ms/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

