$ ->
  class self.EstimatePriceViewModel extends EditableObjectViewModel
    @include ContainDialogHelper

    constructor: (object, readonly = false) ->
      super(object, 'estimate/prices', readonly)

      @dialog_catalogs = ko.observable(null)
      @initializeContainDialogHelper()

    namespace: =>
      ""

    onDialogInitializing: (dialogId) =>
      if dialogId == 'catalogs_selector'
        DialogCatalogsViewModel.all({}, @dialog_catalogs)
