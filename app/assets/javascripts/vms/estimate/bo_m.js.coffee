$ ->
  class self.BoMViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/bo_ms', readonly)

      @dialog_catalogs = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

    indexOfMachinery: (item) ->
      @object.machinery.indexOf(item)

    indexOfMaterials: (item) ->
      @object.materials.indexOf(item)

    resourceClear: =>
      @object.bo_m.resource_id(null)
      true

    elementResourceClear: (asset) =>
      asset.resource_id(null)
      true

    addMachinery: () =>
      @object.machinery.push(@createElement())

    addMaterials: () =>
      @object.materials.push(@createElement())

    createElement: () =>
      {
        uid: ko.observable()
        resource_id: ko.observable()
        resource:
          tag: ko.observable()
          mu: ko.observable()
        amount: ko.observable()
      }

    removeMachinery: (item) =>
      @object.machinery.remove item

    removeMaterials: (item) =>
      @object.materials.remove item

    namespace: =>
      ""

    select: (object) =>
      @select_item(object)
      @object.bo_m.catalog_id(object.id)
      @object.catalog.tag(object.tag)
      $("##{@dialog_id}").dialog( "close" )

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'catalogs_selector'
        $.getJSON('estimate/catalogs/data.json', {}, (data) =>
          @dialog_catalogs(new EstimateBomCatalogsViewModel(data))
        )

  class self.EstimateBomCatalogsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'estimate/catalogs/data.json'
      @filter =
        tag: ko.observable('')
      @parents = ko.observableArray([{id: null, tag: I18n.t("views.estimates.catalogs.root")}])

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
      self.application.object().select(object)
