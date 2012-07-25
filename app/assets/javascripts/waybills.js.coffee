$ ->
  class self.WaybillsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/waybills/data.json'

      @filter =
        created: ko.observable('')
        document_id: ko.observable('')
        distributor: ko.observable('')
        storekeeper: ko.observable('')
        storekeeper_place: ko.observable('')
        state: ko.observable('')

      super(data)

      @params =
        search: @filter
        page: @page
        per_page: @per_page

    show: (object) ->
      location.hash = "documents/waybills/#{object.id}"

    generateItemsUrl: (object) => "/waybills/#{object.id}/resources.json"

    generateChildrenParams: (object) => {}

    createChildrenViewModel: (data, params, object) =>
      new WaybillResourcesViewModel(data, params, object)

  class self.WaybillResourcesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/waybills/#{object.id}/resources.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
