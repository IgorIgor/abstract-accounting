$ ->
  class self.EstimatePricesViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/estimate/prices/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
