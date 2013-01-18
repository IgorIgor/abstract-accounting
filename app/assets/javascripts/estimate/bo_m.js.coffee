$ ->
  class self.BoMViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      @resource = ko.mapping.fromJS(object.resource)
      @elements = ko.mapping.fromJS(object.elements)
      super(object, 'bo_ms', readonly)
      @readonly = ko.observable(readonly)
      @namespace = "estimate"
      @id_presence = ko.observable(object.bo_m.id?)

      @dialog_catalogs = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

    resourceClear: =>
      @object.bo_m.resource_id(null)
      true

    elementResourceClear: (asset) =>
      asset.id(null)
      true

    addElement: (idx) =>
      asset =
        code: ko.observable(null)
        id: ko.observable(null)
        tag: ko.observable(null)
        mu: ko.observable(null)
        rate: ko.observable(null)
      @object.elements[idx].push asset

    removeElement: (idx,asset) =>
      @object.elements[idx].remove asset

    select: (object) =>
      @select_item(object)
      @object.catalog.id(object.id)
      @object.catalog.tag(object.tag)
      $("##{@dialog_id}").dialog( "close" )

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'catalogs_selector'
        $.getJSON('estimate/catalogs/data.json', {}, (data) =>
          @dialog_catalogs(new BomCatalogsViewModel(data))
        )

  class self.BomCatalogsViewModel extends FolderViewModel
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
