$ ->
  class self.WaybillsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/waybills/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
