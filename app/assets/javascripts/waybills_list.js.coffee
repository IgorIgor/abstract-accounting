$ ->
  class self.WaybillsListViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/waybills/list.json'
      @total = ko.observable(data.total) if data.total?

      @filter =
        created: ko.observable('')
        document_id: ko.observable('')
        distributor: ko.observable('')
        storekeeper: ko.observable('')
        storekeeper_place: ko.observable('')
        state: ko.observable('')
        resource_tag: ko.observable('')

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page
      $.each(params, (key, value) =>
        @params[key] = value
      )
