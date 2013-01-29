$ ->
  class self.EstimatePricesViewModel extends FolderViewModel
    constructor: (data, options = {}) ->
      @url = '/estimate/prices/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

      @params.catalog_id = options.catalog_id if options.catalog_id?
