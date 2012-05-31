$ ->
  class self.PlacesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/places/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page
