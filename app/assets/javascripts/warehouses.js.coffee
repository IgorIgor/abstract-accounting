$ ->
  class self.WarehouseViewModel
    constructor: (objects) ->
      @documents = ko.observableArray(objects)
      @filter =
        place: ko.observable('')
        tag: ko.observable('')
        real_amount: ko.observable('')
        exp_amount: ko.observable('')
        mu: ko.observable('')

    filterData: =>
      $.getJSON('/warehouses/data.json', like: @filter, (objects) =>
        @documents(objects)
      )
