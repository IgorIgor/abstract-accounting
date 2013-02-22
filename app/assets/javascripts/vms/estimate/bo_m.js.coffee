$ ->
  class self.BoMViewModel extends EditableObjectViewModel
    @include ContainDialogHelper

    constructor: (object, readonly = false) ->
      super(object, 'estimate/bo_ms', readonly)

      @dialog_catalogs = ko.observable(null)
      @initializeContainDialogHelper()

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

    onDialogInitializing: (dialogId) =>
      if dialogId == 'catalogs_selector'
        DialogCatalogsViewModel.all({}, @dialog_catalogs)
