$ ->
  class self.WarehouseViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/warehouses/data.json'

      super(data)

      @filter =
        place: ko.observable('')
        tag: ko.observable('')
        real_amount: ko.observable('')
        exp_amount: ko.observable('')
        mu: ko.observable('')

      @params =
        like: @filter
        page: @page
        per_page: @per_page

    filterData: =>
      @page(1)
      $.getJSON(@url, @params, (data) =>
        @documents(data.objects)
        @count(data.count)
        @range(@rangeGenerate())
      )
