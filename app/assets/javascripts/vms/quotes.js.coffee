$ ->
  class self.QuotesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/quote/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

    show: (object) ->
      location.hash = "documents/quote/#{object.id}"
