$ ->
  class self.WaybillsListViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/waybills/list.json'
      @total = ko.observable(data.total) if data.total?

      @filter_state = ko.observableArray(@defaultStateList)

      @filter =
        created: ko.observable('')
        document_id: ko.observable('')
        distributor: ko.observable('')
        storekeeper: ko.observable('')
        storekeeper_place: ko.observable('')
        state: ko.observable('')
        resource_tag: ko.observable('')
        states: @filter_state

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page
      $.each(params, (key, value) =>
        @params[key] = value
      )

    onDataReceived: (data) =>
      super(data)
      @total(data.total)

    show: (object) ->
      'waybills'

    onDataReceived: (data) =>
      @total(data.total)
      @filter_state(@defaultStateList) if @filter_state().length == 0
      super(data)

    defaultStateList: ["#{StatableViewModel.INWORK}",
      "#{StatableViewModel.CANCELED}",
      "#{StatableViewModel.APPLIED}"]
