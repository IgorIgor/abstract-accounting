$ ->
  class self.EstimatePriceListsViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/estimate/price_lists/data.json'
      @namespace = "estimate"

      super(data)

      @params =
        page: @page
        per_page: @per_page

  class self.PriceListViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      @resource = ko.mapping.fromJS(object.resource)
      @elements = ko.mapping.fromJS(object.elements)
      super(object, 'estimate/price_lists', readonly)
      @readonly = ko.observable(readonly)
      @id_presence = ko.observable(object.price_list.id?)
