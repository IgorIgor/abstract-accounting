$ ->
  class self.EstimateLocalsViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/estimate/locals/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
