$ ->
  class self.DealsViewModel extends FolderViewModel
    constructor: (data, canSelect = false) ->
      @url = '/deals/data.json'
      @canSelect = ko.observable(canSelect)

      super(data)

      @params =
        page: @page
        per_page: @per_page

    select: (object) =>
      ko.dataFor($('#main').get(0)).deal_id(object.id)
      ko.dataFor($('#main').get(0)).deal_tag(object.tag)
      ko.cleanNode($('#container_selection').get(0))
      $('#container_selection').remove()
      $('#main').show()

    toConditions: (object) ->
      unless object.has_rules
        date = $.datepicker.formatDate('yy-mm-dd', new Date())
        filter =
          date_from: date
          date_to: date
          deal_id: object.id
        location.hash = "transcripts?#{$.param(filter)}"
