$ ->
  class self.WarehouseViewModel
    constructor: (data) ->
      @documents = ko.observableArray(data.warehouses)

      @page = ko.observable(data.page || 1)
      @per_page = ko.observable(data.per_page)
      @count = ko.observable(data.count)
      @range = ko.observable(@rangeGenerate())

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
      $.getJSON('/warehouses/data.json', @params, (data) =>
        @documents(data.warehouses)
        @count(data.count)
        @range(@rangeGenerate())
      )

    prev: =>
      @page(@page() - 1)
      $.getJSON('/warehouses/data.json', @params, (data) =>
        @documents(data.warehouses)
        @count(data.count)
        @range(@rangeGenerate())
      )

    next: =>
      @page(@page() + 1)
      $.getJSON('/warehouses/data.json', @params, (data) =>
        @documents(data.warehouses)
        @count(data.count)
        @range(@rangeGenerate())
      )

    rangeGenerate: =>
      startRange = (@page() - 1)*@per_page() + 1
      endRange = (@page() - 1)*@per_page() + @per_page()
      endRange = @count() if endRange > @count()
      "#{startRange}-#{endRange}"
