$ ->
  class self.EntitiesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/entities/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
