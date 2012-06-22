$ ->
  class self.WarehouseViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/warehouses/data.json'
      @group_by = ko.observable('')

      @filter =
        place: ko.observable('')
        tag: ko.observable('')
        real_amount: ko.observable('')
        exp_amount: ko.observable('')
        mu: ko.observable('')

      super(data)

      @params =
        like: @filter
        page: @page
        per_page: @per_page
        group_by: @group_by()
      @params['where'] = params.where if params.where?

      @group_by.subscribe(@groupBy)

    groupBy: =>
      if @group_by() == ''
        location.hash = "#warehouses"
      else
        location.hash = "#warehouses?group_by=#{@group_by()}"
