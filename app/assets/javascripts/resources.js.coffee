$ ->
  class self.ResourcesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/resources/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page

    showBalances: (object) ->
      unless $('#slide_menu_conditions').is(":visible")
        $('#arrow_conditions').removeClass('arrow-down-slide')
        $('#arrow_conditions').addClass('arrow-up-slide')
        $("#slide_menu_conditions").slideDown()
      params =
        resource: { id: object.id, type: object.klass }
      location.hash = "#balance_sheet?#{$.param(params)}"
