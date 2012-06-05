$ ->
  class self.AllocationsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/allocations/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page
