$ ->
  class self.EstimateLocalViewModel extends CommentableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/locals', readonly)
      @dialog_boms = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null
      @idx = 0
      @openedBomIds = ko.observableArray([])

    namespace: =>
      ""

    visibleApply: =>
      @readonly() && !@object.local.approved()? && !@object.local.canceled()?

    disableEdit: =>
      @disable() || !@readonly() || @object.local.approved()? || @object.local.canceled()?

    disableButton: =>
      @disable()

    apply: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/apply", {}, true)

    cancel: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/cancel", {}, true)

    resourceVisibility: (bomId) =>
      bomId in @openedBomIds()

    showResources: (obj, event) =>
      el = $(event.target).find('span')
      el = $(event.target) unless el.length
      el.toggleClass('ui-icon-circle-plus')
      el.toggleClass('ui-icon-circle-minus')

      if obj.price.bom.id() in @openedBomIds()
        @openedBomIds.remove(obj.price.bom.id())
      else
        @openedBomIds.push(obj.price.bom.id())

    addItem: =>
      $.getJSON("estimate/prices/find.json", {bom_id: @select_item().id, catalog_id: @object.prices_catalog.id()}, (data) =>
        if data.id?
          item =
            price:
              id: data.id
              bom: ko.mapping.fromJS(@select_item())
              direct_cost: data.direct_cost
              workers_cost: data.workers_cost
              drivers_cost: data.drivers_cost
              machinery_cost: data.machinery_cost
              materials_cost: data.materials_cost
            total_materials_cost: ko.observable(0)
            total_machinery_cost: ko.observable(0)
            total_drivers_cost: ko.observable(0)
            total_workers_cost: ko.observable(0)
            total_direct_cost: ko.observable(0)
            correct: ko.observable(true)
            amount: ko.observable(0.0).extend({ numeric: 4 })

          item.correct.subscribe((val) =>
            @correct_change(item, val)
          )
          item.amount.subscribe((val) ->
            item.total_direct_cost(item.price.direct_cost * val)
            item.total_workers_cost(item.price.workers_cost * val)
            item.total_drivers_cost(item.price.drivers_cost * val)
            item.total_machinery_cost(item.price.machinery_cost * val)
            item.total_materials_cost(item.price.materials_cost * val)
          )
          @object.items.push(item)
        else
          alert("Нету подходящего списка цен!")
      )

    correct_change: (item, val) =>
      id = @object.items().indexOf(item)
      if val
        $("#item_#{id} input").removeClass('error')
      else
        $("#item_#{id} input").addClass('error')

    removeItem: (object) =>
      @object.items.remove(object)

    select: (object) =>
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )
      if @dialog_id == 'boms_selector'
        @addItem()

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'boms_selector'
        $.getJSON('estimate/bo_ms/data.json', {catalog_pid: @object.boms_catalog.id()}, (data) =>
          @dialog_boms(new DialogEstimateBomsViewModel(data, @object.boms_catalog.id()))
        )
