$ ->
  class self.AllocationsListViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/allocations/list.json'

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

    onDataReceived: (data) =>
      @filter_state(@defaultStateList) if @filter_state().length == 0
      super(data)

    defaultStateList: ["#{StatableViewModel.INWORK}",
      "#{StatableViewModel.CANCELED}",
      "#{StatableViewModel.APPLIED}"]
