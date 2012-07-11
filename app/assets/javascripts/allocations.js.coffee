$ ->
  class self.AllocationsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/allocations/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page

    show: (object) ->
      location.hash = "documents/allocations/#{object.id}"

    generateItemsUrl: (object) => "/allocations/#{object.id}/resources.json"

    generateChildrenParams: (object) => {}

    createChildrenViewModel: (data, params, object) =>
      new AllocationResourcesViewModel(data, params, object)

  class self.AllocationResourcesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/allocations/#{object.id}/resources.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
