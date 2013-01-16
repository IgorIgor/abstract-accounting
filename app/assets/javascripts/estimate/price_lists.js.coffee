$ ->
  class self.EstimatePriceListsViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/estimate/price_lists/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
