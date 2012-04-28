$ ->
  class self.WarehouseViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/warehouses/data.json'

      @filter =
        place: ko.observable('')
        tag: ko.observable('')
        real_amount: ko.observable('')
        exp_amount: ko.observable('')
        mu: ko.observable('')

      super(data)
