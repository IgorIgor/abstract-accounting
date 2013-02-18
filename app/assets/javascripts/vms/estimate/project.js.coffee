$ ->
  class self.EstimateProjectViewModel extends CommentableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/projects', readonly)
      @dialog_catalogs = ko.observable(null)
      @dialog_places = ko.observable(null)
      @dialog_entities = ko.observable(null)
      @dialog_legal_entities = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null
      if readonly
        @object.locals = ko.observable(new EstimateLocalsViewModel({objects: []}, {project_id: @object.id()}))
        @object.locals().getPaginateData()

    namespace: =>
      ""

    select: (object) =>
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'places_selector'
        $.getJSON('places/data.json', {}, (data) =>
          @dialog_places(new ProjectPlacesViewModel(data))
        )
      if dialogId == 'entities_selector'
        $.getJSON('entities/list.json', {}, (data) =>
          @dialog_entities(new ProjectEntitiesViewModel(data))
        )
      if dialogId == 'legal_entities_selector'
        $.getJSON('legal_entities/list.json', {}, (data) =>
          @dialog_legal_entities(new ProjectLegalEntitiesViewModel(data))
        )
      if dialogId == 'catalogs_selector'
        $.getJSON('estimate/catalogs/data.json', {}, (data) =>
          @dialog_catalogs(new ProjectCatalogsViewModel(data))
        )

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

  class self.ProjectPlacesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'places/data.json'
      @filter =
        tag: ko.observable('')
      super(data)

    select: (object) =>
      window.application.object().select(object)

  class self.ProjectEntitiesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = "entities/list.json"
      @filter =
        tag: ko.observable('')
      super(data)

    select: (object) =>
      window.application.object().select(object)

  class self.ProjectLegalEntitiesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = "legal_entities/list.json"
      @filter =
        name: ko.observable('')
      super(data)

    select: (object) =>
      window.application.object().select(object)

  class self.ProjectCatalogsViewModel extends FolderViewModel
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
