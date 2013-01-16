$ ->
  class self.AllocationsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/allocations/data.json'

      @filter_state = ko.observableArray(@defaultStateList)

      @filter =
        created: ko.observable('')
        foreman: ko.observable('')
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

    getType: (object) ->
      'allocations'

    generateItemsUrl: (object) => "/allocations/#{object.id}/resources.json"

    generateChildrenParams: (object) => {}

    createChildrenViewModel: (data, params, object) =>
      new AllocationResourcesViewModel(data, params, object)

    onDataReceived: (data) =>
      @filter_state(@defaultStateList) if @filter_state().length == 0
      super(data)

    defaultStateList: ["#{StatableViewModel.INWORK}",
      "#{StatableViewModel.CANCELED}",
      "#{StatableViewModel.APPLIED}"]

  class self.AllocationResourcesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/allocations/#{object.id}/resources.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
