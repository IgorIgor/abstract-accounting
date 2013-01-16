$ ->
  class self.ForemanViewModel extends FolderViewModel
    constructor: (data) ->
      @url = "/foreman/resources/data.json"
      @from = ko.observable(data.from)
      @to = ko.observable(data.to)
      @filter =
        tag: ko.observable('')
        mu: ko.observable('')
        amount: ko.observable('')

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page
        from: @from
        to: @to

    print: =>
      delete @params.page
      delete @params.per_page
      url = "foreman/resources/data.pdf?#{$.param(normalizeHash(ko.mapping.toJS(@params)))}"
      window.open(url, '_blank')
