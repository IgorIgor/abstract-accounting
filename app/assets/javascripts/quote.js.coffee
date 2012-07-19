$ ->
  class self.QuoteViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/quote/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
