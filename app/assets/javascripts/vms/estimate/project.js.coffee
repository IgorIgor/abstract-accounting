$ ->
  class self.EstimateProjectViewModel extends CommentableViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/projects', readonly)

      @dialog_places = ko.observable(null)
      @dialog_entities = ko.observable(null)
      @dialog_legal_entities = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

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
