$ ->
  class self.PlacesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/places/data.json'

      super(data)

      @selected = ko.observableArray()
      @params =
        page: @page
        per_page: @per_page

    getType: (object) =>
      'places'

    showBalances: ->
      unless $('#slide_menu_conditions').is(":visible")
        $('#arrow_conditions').removeClass('arrow-down-slide')
        $('#arrow_conditions').addClass('arrow-up-slide')
        $("#slide_menu_conditions").slideDown()
      params =
        place_ids: ko.mapping.toJS(@selected())
      location.hash = "#balance_sheet?#{$.param(params)}"
