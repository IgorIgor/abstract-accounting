$ ->
  class self.WaybillsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/waybills/data.json'

      super(data)

      @orders = {}

      @params =
        page: @page
        per_page: @per_page

    show: (object) ->
      location.hash = "documents/waybills/#{object.id}"

    generateItemsUrl: (object) => "/waybills/#{object.id}/resources.json"

    generateChildrenParams: (object) => {}

    createChildrenViewModel: (data, params, object) =>
      new WaybillResourcesViewModel(data, params, object)

    sortBy: (object, event) =>
      el = $(event.target).find('span')
      el = $(event.target) unless el.length

      key = "#{event.target.id}"
      if @orders[key]?
        @orders[key] = !@orders[key]
        el.toggleClass('ui-icon ui-icon-triangle-1-s')
        el.toggleClass('ui-icon ui-icon-triangle-1-n')
      else
        @orders = {}
        @orders[key] = true
        $(event.target).siblings().find('span').removeClass('ui-icon ui-icon-triangle-1-n ui-icon-triangle-1-s')
        el.addClass('ui-icon ui-icon-triangle-1-s')

      if @orders[key] == true
        @params =
          order:
            type: 'asc'
      else
        @params =
          order:
            type: 'desc'
      @params['order']['field'] = key
      @getPaginateData()

  class self.WaybillResourcesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/waybills/#{object.id}/resources.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
