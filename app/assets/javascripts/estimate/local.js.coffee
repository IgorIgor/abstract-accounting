$ ->
  class self.EstimateLocalViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'locals', readonly)
      @namespace = "estimate"

      @dialog_catalogs = ko.observable(null)
      @dialog_boms = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

      @idx = 0

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

    itemsRefindByCatalog: (val) =>
      item = @object.items()[@idx]
      @idx = @idx + 1
      if @idx > @object.items().length
        @idx = 0
        return true
      $.getJSON("estimate/price_lists/find.json", {bom_uid: item.price_list.bom.uid, catalog_id: val, date: @object.local.date()}, (data) =>
        if data.id? > 0 && data.bom? && data.bom.resource?
          item.price_list.id = data.id
          item.price_list.bom.id = data.bom.id
          item.price_list.bom.resource.tag = data.bom.resource.tag
          item.price_list.bom.resource.mu = data.bom.resource.mu
        else
          item.correct(false)
        @itemsRefindByCatalog(val)
      )

    itemRefindByDate: () =>
      item = @object.items()[@idx]
      @idx = @idx + 1
      if @idx > @object.items().length
        @idx = 0
        return true
      $.getJSON("estimate/price_lists/find.json", {bom_id: item.price_list.bom.id, date: val}, (data) =>
        if data.id? > 0 && data.bom? && data.bom.resource?
          item.price_list.id = data.id
          item.price_list.bom.id = data.bom.id
          item.price_list.bom.resource.tag = data.bom.resource.tag
          item.price_list.bom.resource.mu = data.bom.resource.mu
        else
          item.correct(false)
        @itemRefindByDate(val)
      )

    edit: =>
      @readonly(false)
      @disable(false)
      @method = 'PUT'
      location.hash = "##{@namespace}/#{@route}/#{@object.id()}/edit"

    save: =>
      @disable(true)
      url = "/#{@namespace}/#{@route}"
      if @method == 'PUT'
        url = "/#{@namespace}/#{@route}/#{@object.id()}"
      @ajaxRequest(@method, url, normalizeHash(ko.mapping.toJS(@object)))

    addItem: =>
      $.getJSON("estimate/price_lists/find.json", {bom_id: @select_item().id, date: @object.local.date}, (data) =>
        if data.id?
          item =
            correct: ko.observable(true)
            price_list:
              id: data.id
              bom:
                id: @select_item().id
                uid: @select_item().uid
                resource:
                  tag: @select_item().resource.tag
                  mu: @select_item().resource.mu
            amount: 0.0

          item.correct.subscribe((val) =>
            @correct_change(item, val)
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
        $.getJSON('estimate/bo_ms/data.json', {catalog_id: @object.local.catalog_id()}, (data) =>
          @dialog_boms(new LocalBomsViewModel(data))
        )
      if dialogId == 'catalogs_selector'
        $.getJSON('estimate/catalogs/data.json', {}, (data) =>
          @dialog_catalogs(new LocalCatalogsViewModel(data))
        )

  class self.LocalBomsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'estimate/bo_ms/data.json'
      @filter =
        tag: ko.observable('')

      super(data)

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
