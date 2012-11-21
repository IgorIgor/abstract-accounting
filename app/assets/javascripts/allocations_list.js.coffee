$ ->
  class self.AllocationsListViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/allocations/list.json'

      @filter =
        created: ko.observable('')
        foreman: ko.observable('')
        storekeeper: ko.observable('')
        storekeeper_place: ko.observable('')
        state: ko.observable('')
        resource_tag: ko.observable('')

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page

    getType: (object) ->
      'allocations'
