$ ->
  class self.WaybillsViewModel extends TreeViewModel
    constructor: (data, params = {}) ->
      @url = if params.present? then '/waybills/present.json' else '/waybills/data.json'
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

    getType: (object) ->
      'waybills'

    generateItemsUrl: (object) => "/waybills/#{object.id}/resources.json"

    generateChildrenParams: (object) =>
      params = {}
      params["exp_amount"] = true if @params.exp_amount?
      params

    createChildrenViewModel: (data, params, object) =>
      new WaybillResourcesViewModel(data, params, object)

    onDataReceived: (data) =>
      @total(data.total)
      @filter_state(@defaultStateList) if @filter_state().length == 0
      super(data)

    defaultStateList: ["#{StatableViewModel.INWORK}",
      "#{StatableViewModel.CANCELED}",
      "#{StatableViewModel.APPLIED}"]

  class self.WaybillResourcesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/waybills/#{object.id}/resources.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
      $.each(params, (key, value) =>
        @params[key] = value
      )
