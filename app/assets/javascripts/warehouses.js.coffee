$ ->
  Object.keys = Object.keys || (o) ->
      result = [];
      for name in o
          if o.hasOwnProperty(name)
            result.push(name)
      return result

  class self.GroupedWarehouseViewModel extends GroupedViewModel
    constructor: (data, filter) ->
      super(data, "warehouses", filter)

    generateChildrenParams: (object) =>
      params = {}
      switch @group_by()
        when 'place'
          params = {where: {warehouse_id: {equal_attr: object.group_id}}}
        when 'tag'
          params = {where: {asset_id: {equal_attr: object.group_id}}}
      params

    createChildrenViewModel: (data, params) =>
      new WarehouseViewModel(data, params)


  class self.WarehouseViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/warehouses/data.json'
      @group_by = ko.observable('')

      @filter =
        place: ko.observable('')
        tag: ko.observable('')
        real_amount: ko.observable('')
        exp_amount: ko.observable('')
        mu: ko.observable('')

      super(data)

      @params =
        like: @filter
        page: @page
        per_page: @per_page
        group_by: @group_by()
      $.each(params, (key, value) =>
        @params[key] = value
      )

      @group_by.subscribe(@groupBy)

    groupBy: =>
      if @group_by() == ''
        location.hash = "#warehouses"
      else
        location.hash = "#warehouses?group_by=#{@group_by()}"

    showReport: (object) ->
      params =
        resource_id: object.id
        warehouse_id: object.place_id
      location.hash = "#warehouses/report?#{$.param(params)}"

    print: =>
      url = "warehouses/print.pdf?#{$.param(normalizeHash(ko.mapping.toJS(@params)))}"
      window.open(url, '_blank');

  class self.WarehouseAssetsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/assets.json'

      @filter =
        tag: ko.observable('')

      super(data)

  class self.WarehouseResourceReportViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = "/warehouses/report.json"
      @resource = ko.mapping.fromJS(data.resource)
      @resource_id = ko.observable(params.resource_id)
      @warehouse_id = ko.observable(params.warehouse_id ? data.warehouse_id)
      @place = ko.mapping.fromJS(data.place)
      @total = ko.observable(data.total)
      @warehouses = ko.observable(data.warehouses)
      super(data)

      @dialog = ko.observable(null)
      @dialog_element = null

      @params =
        page: @page
        per_page: @per_page
        resource_id: @resource_id
        warehouse_id: @warehouse_id

      @resource_id.subscribe((val) =>
        return true unless val
        @page(1)
        $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
          @documents(data.objects)
          @count(data.count)
          @range(@rangeGenerate())
          @place.tag(data.place.tag)
          @total(data.total)
        )
      )

    showWaybill: (object) ->
      location.hash = "documents/waybills/#{object.item_id}"

    showAllocation: (object) ->
      location.hash = "documents/allocations/#{object.item_id}"

    print: =>
      params =
        resource_id: @resource_id
        warehouse_id: @warehouse_id
      url = "/warehouses/report.pdf?#{$.param(normalizeHash(ko.mapping.toJS(@params)))}"
      window.open(url, '_blank');

    openDialog: (elementId)=>
      @dialog_element = elementId
      $("##{elementId}").dialog( "open" )
      $.getJSON('/assets.json', {}, (data) =>
        @dialog(new WarehouseAssetsViewModel(data))
      )

    select: (object)=>
      @resource_id(object.id)
      @resource.tag(object.tag)
      @resource.mu(object.mu)
      @dialog(null)
      $("##{@dialog_element}").dialog( "close" )


  class self.WarehouseForemanReportViewModel extends FolderViewModel
    constructor: (data) ->
      @url = "/warehouses/foremen.json"
      @foremen = ko.observable(data.foremen)
      @foreman_id = ko.observable(null)
      @from = ko.observable(data.from)
      @to = ko.observable(data.to)

      @warehouses = ko.observable(data.warehouses)
      @warehouse_id = ko.observable(null)
      @resources = ko.observableHash({})
      @foreman_id.subscribe( =>
        unless @resources.hasKey(@foreman_id())
          @resources.set(@foreman_id(), ko.observableArray([]))
      )
      @print_visibility = ko.computed( =>
        for key in Object.keys(@resources())
          return true if @resources.get(key)().length > 0
        false
      )

      super(data)

      @params =
        page: @page
        per_page: @per_page
        foreman_id: @foreman_id
        from: @from
        to: @to
      if @warehouses().length > 0
        @params['warehouse_id'] = @warehouse_id

    assignForemen: () ->
      if @warehouse_id()
        $.each(@warehouses(), (idx, item)=>
          if item.place_id == @warehouse_id()
            @foremen(item.foremen)
            if @foremen().length == 0
              @clearData()
        )
      else
        @foremen([])
        @clearData()

    print:(all,check) =>
      params =
        from: @from()
        to: @to()
      unless all
        params['foreman_id'] = @foreman_id()
      if check
        params['resource_ids'] = @resources()
      if @warehouses().length > 0
        params['warehouse_id'] = @warehouse_id()
      url = "warehouses/foremen.xls?#{$.param(params)}"
      window.open(url, '_blank');
