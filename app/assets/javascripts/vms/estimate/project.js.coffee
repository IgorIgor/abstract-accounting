$ ->
  class self.EstimateProjectViewModel extends CommentableViewModel
    @include ContainDialogHelper

    constructor: (object, readonly = false) ->
      super(object, 'estimate/projects', readonly)
      @dialog_catalogs = ko.observable(null)
      @dialog_places = ko.observable(null)
      @dialog_entities = ko.observable(null)
      @dialog_legal_entities = ko.observable(null)
      @initializeContainDialogHelper()
      if readonly
        @object.locals = ko.observable(new EstimateLocalsViewModel({objects: []}, {project_id: @object.id()}))
        @object.locals().getPaginateData()

    namespace: =>
      ""

    onDialogInitializing: (dialogId) =>
      if dialogId == 'places_selector'
        DialogPlacesViewModel.all({}, @dialog_places)
      if dialogId == 'entities_selector'
        DialogEntitiesViewModel.all({}, @dialog_entities)
      if dialogId == 'legal_entities_selector'
        DialogLegalEntitiesViewModel.all({}, @dialog_legal_entities)
      if dialogId == 'catalogs_selector'
        DialogCatalogsViewModel.all({}, @dialog_catalogs)

    clearCustomerId: =>
      @object.project.customer_id(null)
      true

    clearPlaceId: =>
      @object.project.place_id(null)
      true

    changeTab: =>
      @clearCustomerId
      $.each($("div.tab"), (idx, div) =>
        if $(div).data("tabId").toString() == @object.project.customer_type()
          $(div).css('display', 'block')
        else
          $(div).css('display', 'none')
      )

    showLocal: (object) =>
      location.hash = "#estimate/locals/#{object.id()}"

    addLocal: =>
      location.hash = "#estimate/locals/new?#{$.param(project_id: @object.id())}"
