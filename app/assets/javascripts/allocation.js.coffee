$ ->
  class self.AllocationViewModel extends StatableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'allocations', readonly)
      @disable_warehouse = object.allocation.warehouse_id?
      @motion = ko.observable("0")
      @motion.subscribe((val) =>
        @object.foreman.tag(null)
        @object.allocation.foreman_id(null)
        if val == '0' && @object.allocation.warehouse_id()
          @assignForemanPlace()
        else
          @object.foreman_place.tag(null)
          @object.allocation.foreman_place_id(null)
      )

      @url = '/warehouses/data.json'
      @warehouse = ko.observable(null)

      @params =
        equal:
          warehouse_id: null

      @availableMode = ko.observable('0')
      @availableMode.subscribe((val) =>
        @url =
          "/#{if val == '0' then 'warehouses/data' else 'waybills/present'}.json"
        @loadAvailableResources(false)
      )

      @object.allocation.warehouse_id.subscribe((val) =>
        if @motion() == '0'
          if val
            @assignForemanPlace()
          else
            @object.foreman_place.tag(null)
            @object.allocation.foreman_place_id(null)
        @loadAvailableResources()
      )

      #used when motion to storekeeper
      @remote_warehouse_id = ko.observable(null)
      @remote_warehouse_id.subscribe((val) =>
        if @motion() == '1'
          if val
            @object.foreman_place.tag(@findWarehouse(val).tag())
            @object.allocation.foreman_place_id(@findWarehouse(val).place_id())
          else
            @object.foreman_place.tag(null)
            @object.allocation.foreman_place_id(null)
      )

      @remote_warehouses = ko.computed(=>
        place_id = null
        if @object.allocation.warehouse_id()
          place_id = @findWarehouse(@object.allocation.warehouse_id()).place_id()
        $.grep(@object.warehouses(), (item) =>
          item.place_id() != place_id
        )
      , self)

      @loadAvailableResources() unless readonly

    findWarehouse: (id) =>
      $.grep(@object.warehouses(), (item) ->
        item.id() == id
      )[0]

    assignForemanPlace: () =>
      @object.foreman_place.tag(@findWarehouse(@object.allocation.warehouse_id()).tag())
      @object.allocation.foreman_place_id(
        @findWarehouse(@object.allocation.warehouse_id()).place_id()
      )

    unselectResource: (resource) =>
      @object.items.remove(resource)
      @getPaginateData()

    selectResource: (resource) =>
      resource.amount = ko.observable(resource.exp_amount)
      @object.items.push(resource)
      @getPaginateData()

    selectWaybill: (waybill) =>
      if waybill.subitems() != null && waybill.subitems().documents.length
        for resource in waybill.subitems().documents
          exist = $.grep(@object.items(), (r) -> return r.id == resource.id)[0]
          if exist
            exist.waybill_id = waybill.id
            if resource.amount + exist.amount() > resource.exp_amount
              exist.amount(resource.exp_amount)
            else
              exist.amount(resource.amount + exist.amount())
          else
            resource.waybill_id = waybill.id
            if resource.amount > resource.exp_amount
              resource.amount = ko.observable(resource.exp_amount)
            else
              resource.amount = ko.observable(resource.amount)
            @object.items.push(resource)
        @getPaginateData()
      else
        $.getJSON("/waybills/#{waybill.id}/resources.json", {all: true, exp_amount: true},
        (items) =>
          for resource in items.objects
            exist = $.grep(@object.items(), (r) -> return r.id == resource.id)[0]
            if exist
              exist.waybill_id = waybill.id
              if resource.amount + exist.amount() > resource.exp_amount
                exist.amount(resource.exp_amount)
              else
                exist.amount(resource.amount + exist.amount())
            else
              resource.waybill_id = waybill.id
              if resource.amount > resource.exp_amount
                resource.amount = ko.observable(resource.exp_amount)
              else
                resource.amount = ko.observable(resource.amount)
              @object.items.push(resource)
          @getPaginateData()
        )

    loadAvailableResources: (clearSelected = true) =>
      return false if @readonly()
      @object.items([]) if clearSelected
      @warehouse(null)
      if @object.allocation.warehouse_id()
        @getPaginateData()

    print: =>
      location.href = "allocations/#{@object.id()}.pdf"

    getPaginateData: =>
      if @object.items().length > 0
        if @availableMode() == '0'
          @params['without'] = $.map(@object.items(), (r) -> r.id)
        else
          @params['without'] = $.map(@object.items(), (r) -> r.waybill_id)
      else if @params.hasOwnProperty('without')
        delete @params['without']
      @params['equal']['warehouse_id'] = @findWarehouse(
        @object.allocation.warehouse_id()).place_id()
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        if @availableMode() == '0'
          @warehouse(new WarehouseViewModel(data, @params))
        else
          @params["exp_amount"] = true
          @warehouse(new WaybillsViewModel(data, @params))
      )

    search_area: =>
      $('#resource_filter').toggle()
      unless $('#resource_filter').is(":visible")
        @warehouse().clearFilter()
        @warehouse().filterData()
