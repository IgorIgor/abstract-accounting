$ ->
  class self.EstimateLocalViewModel extends CommentableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/locals', readonly)
      @dialog_catalogs = ko.observable(null)
      @dialog_boms = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null
      @idx = 0
      @openedBomIds = ko.observableArray([])

      @can_add_items = ko.computed(=>
        @object.catalog.id()? && @object.local.date()?
      , self)

      @object.local.date.subscribe((val) =>
        if @object.items().length > 0
          alert("Список цен для материалов будет переискан")
          @itemRefindByDate(val)
      )

      @object.local.catalog_id.subscribe((val) =>
        if @object.items().length > 0
          alert("Материалы будут переисканы в номов каталоге")
          @itemsRefindByCatalog(val)
      )

    namespace: =>
      ""

    visibleApply: =>
      @readonly() && !@object.local.approved()?

    disableEdit: =>
      @disable() || !@readonly() || @object.local.approved()?

    disableButton: =>
      @disable()

    apply: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/apply", {}, true)

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

    itemsRefindByCatalog: (val) =>
      item = @object.items()[@idx]
      @idx = @idx + 1
      if @idx > @object.items().length
        @idx = 0
        return true
      $.getJSON("estimate/prices/find.json", {bom_uid: item.price.bom.uid, catalog_id: val, date: @object.local.date()}, (data) =>
        if data.id? > 0 && data.bom? && data.bom.resource?
          item.price = ko.mapping.fromJS(data)
          item.correct(true)
        else
          item.correct(false)
        @itemsRefindByCatalog(val)
      )

    itemRefindByDate: (val) =>
      item = @object.items()[@idx]
      @idx = @idx + 1
      if @idx > @object.items().length
        @idx = 0
        return true
      $.getJSON("estimate/prices/find.json", {bom_id: item.price.bom.id, date: val}, (data) =>
        if data.id? > 0 && data.bom? && data.bom.resource?
          item.price = ko.mapping.fromJS(data)
          item.correct(true)
        else
          item.correct(false)
        @itemRefindByDate(val)
      )

    addItem: =>
      $.getJSON("estimate/prices/find.json", {bom_id: @select_item().id, date: @object.local.date()}, (data) =>
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
      if @dialog_id == 'catalogs_selector'
        @object.catalog.id(object.id)
        @object.catalog.tag(object.tag)
        @object.local.catalog_id(object.id)

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'boms_selector'
        $.getJSON('estimate/bo_ms/data.json', {catalog_pid: @object.local.catalog_id()}, (data) =>
          @dialog_boms(new DialogEstimateBomsViewModel(data, @object.local.catalog_id()))
        )
      if dialogId == 'catalogs_selector'
        $.getJSON('estimate/catalogs/data.json', {}, (data) =>
          @dialog_catalogs(new LocalCatalogsViewModel(data))
        )

  class self.LocalCatalogsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'estimate/catalogs/data.json'
      @filter =
        tag: ko.observable('')
      @parents = ko.observableArray([{id: null, tag: "Главный каталог"}])

      super(data)

    selectItem: (object) =>
      @parents.push(object)
      @params["parent_id"] = object.id
      @filterData()

    selectParent: (object) =>
      index = @parents().indexOf(object)
      @parents(@parents().slice(0, index+1))
      @params["parent_id"] = object.id
      @filterData()

    select: (object) =>
      window.application.object().select(object)
