$ ->
  class self.DealsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/deals/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
