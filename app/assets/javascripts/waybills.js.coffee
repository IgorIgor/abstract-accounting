$ ->
  class self.WaybillsViewModel extends TreeViewModel
    constructor: (data, params = {}) ->
      @url = '/waybills/data.json'
      @total = ko.observable(data.total) if data.total?

      @filter =
        created: ko.observable('')
        document_id: ko.observable('')
        distributor: ko.observable('')
        storekeeper: ko.observable('')
        storekeeper_place: ko.observable('')
        state: ko.observable('')
        resource_name: ko.observable('')

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page
      $.each(params, (key, value) =>
        @params[key] = value
      )

    show: (object) ->
      location.hash = "documents/waybills/#{object.id}"

    generateItemsUrl: (object) => "/waybills/#{object.id}/resources.json"

    generateChildrenParams: (object) =>
      params = {}
      params["exp_amount"] = true if @params.exp_amount?
      params

    createChildrenViewModel: (data, params, object) =>
      new WaybillResourcesViewModel(data, params, object)

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
