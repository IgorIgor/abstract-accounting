$ ->
  class self.ForemanViewModel extends FolderViewModel
    constructor: (data) ->
      @url = "/foreman/resources/data.json"
      @from = ko.observable(data.from)
      @to = ko.observable(data.to)

      super(data)

      @params =
        page: @page
        per_page: @per_page
        from: @from
        to: @to
