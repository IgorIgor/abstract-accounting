$ ->
  class self.AllocationViewModel extends StatableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'allocations', readonly)
      @disable_storekeeper = if object.allocation.storekeeper_id then true else false
      @availableResources = ko.observableArray([])

      @url = '/warehouses/data.json'

      @page = ko.observable()
      @per_page = ko.observable()
      @count = ko.observable()
      @range = ko.observable()

      @params =
        equal:
          storekeeper_id: @object.allocation.storekeeper_id
          storekeeper_place_id: @object.allocation.storekeeper_place_id
        page: @page
        per_page: @per_page

      @availableMode = ko.observable('0')
      @availableMode.subscribe((val) =>
        @url = "/#{if val == '0' then 'warehouses' else 'waybills'}/data.json"
        @loadAvailableResources(false)
      )

      @loadAvailableResources() unless readonly

    selectResource: (resource) =>
      resource.amount = ko.observable(resource.exp_amount)
      @object.items.push(resource)
      @getPaginateData()

    unselectResource: (resource) =>
      @object.items.remove(resource)
      @getPaginateData()

    selectWaybill: (waybill) =>
      if waybill.resources.items().length
        for resource in waybill.resources.items()
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
        $.getJSON("/waybills/#{waybill.id}/resources.json", null, (items) =>
          for resource in items
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
      @object.items([]) if clearSelected
      @availableResources([])
      if @object.allocation.storekeeper_id() && @object.allocation.storekeeper_place_id()
        @page(1)
        @getPaginateData()
      else
        @page('')
        @per_page('')
        @count(0)
        @range(@rangeGenerate())

    print: =>
      location.href = "allocations/#{@object.id()}.pdf"

    prev: =>
      @page(@page() - 1)
      @getPaginateData()

    next: =>
      @page(@page() + 1)
      @getPaginateData()

    getPaginateData: =>
      if @object.items().length > 0
        if @availableMode() == '0'
          @params['without'] = $.map(@object.items(), (r) -> r.id)
        else
          @params['without'] = $.map(@object.items(), (r) -> r.waybill_id)
      else if @params.hasOwnProperty('without')
        delete @params['without']
      $.getJSON(@url, normalizeHash(ko.mapping.toJS(@params)), (data) =>
        @availableResources([])
        for obj in data.objects
          obj.resources =
            show: ko.observable(false)
            items: ko.observableArray([]) if @availableMode()
          @availableResources.push(obj)

        @per_page(data.per_page)
        @count(data.count)
        @range(@rangeGenerate())

        if data.objects.length == 0 && @page() > 1
          @page(@page() - 1)
          @getPaginateData()
      )

    rangeGenerate: =>
      startRange = if @count() then (@page() - 1)*@per_page() + 1 else 0
      endRange = (@page() - 1)*@per_page() + @per_page()
      endRange = @count() if endRange > @count()
      "#{startRange}-#{endRange}"

    treeMapping: (data, event) =>
      el = $(event.target).find('span')
      el = $(event.target) unless el.length

      el.toggleClass('ui-icon-circle-plus')
      el.toggleClass('ui-icon-circle-minus')

      data.resources.show(
        if data.resources.show()
          false
        else
          unless data.resources.items().length
            $.getJSON("/waybills/#{data.id}/resources.json", null, (items) =>
              data.resources.items(items)
            )
          true
      )
