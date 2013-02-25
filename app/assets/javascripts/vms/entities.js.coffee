$ ->
  class self.EntitiesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/entities/data.json'

      super(data)

      @selected = ko.observableArray()
      @params =
        page: @page
        per_page: @per_page

    getType: (object) ->
      if object.klass == "Entity"
        "entities"
      else
        "legal_entities"

    showBalances: ->
      unless $('#slide_menu_conditions').is(":visible")
        $('#arrow_conditions').removeClass('arrow-down-slide')
        $('#arrow_conditions').addClass('arrow-up-slide')
        $("#slide_menu_conditions").slideDown()
      params =
        entities: ko.mapping.toJS(@selected)
      location.hash = "#balance_sheet?#{$.param(params)}"

  class self.DialogEntitiesViewModel extends FolderViewModel
    @__data_url = '/entities/list.json'
    constructor: (data) ->
      @url = "entities/list.json"
      @filter =
        tag: ko.observable('')
      super(data)

    @include DialogsHelper

  class self.DialogLegalEntitiesViewModel extends FolderViewModel
    @__data_url = '/legal_entities/list.json'
    constructor: (data) ->
      @url = "legal_entities/list.json"
      @filter =
        name: ko.observable('')
      super(data)

    @include DialogsHelper
