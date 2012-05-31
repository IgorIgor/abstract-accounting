$ ->
  class self.AssetsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/assets/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page
