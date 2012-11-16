$ ->
  class self.EntitiesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/entities/data.json'

      super(data)

      @selected = ko.observableArray()
      @params =
        page: @page
        per_page: @per_page

    show: (entity) ->
      page = if entity.klass == "Entity" then "entities" else "legal_entities"
      location.hash = "#documents/#{page}/#{entity.id}"

    showBalances: ->
      unless $('#slide_menu_conditions').is(":visible")
        $('#arrow_conditions').removeClass('arrow-down-slide')
        $('#arrow_conditions').addClass('arrow-up-slide')
        $("#slide_menu_conditions").slideDown()
      params =
        entities: ko.mapping.toJS(@selected)
      location.hash = "#balance_sheet?#{$.param(params)}"
