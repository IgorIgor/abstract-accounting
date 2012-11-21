$ ->
  class self.DealsViewModel extends TreeViewModel
    constructor: (data, canSelect = false) ->
      @url = '/deals/data.json'
      @canSelect = ko.observable(canSelect)

      super(data)

      @selected = ko.observableArray()
      @params =
        page: @page
        per_page: @per_page

     getType: (object) =>
      'deals'

    toReport: =>
      rules = ko.utils.arrayFirst(@documents(), (item) =>
        item.id == @selected()[0] && item.has_rules
      )
      date = $.datepicker.formatDate('yy-mm-dd', new Date())
      if @selected().length == 1 && !rules
        filter =
          deal_id: @selected()[0]
        filter["date_to"] = filter["date_from"] = date
        location.hash = "transcripts?#{$.param(filter)}"
      else
        filter =
          deal_ids: ko.mapping.toJS(@selected())
          date: date
        location.hash = "general_ledger?#{$.param(filter)}"

    select: (object) =>
      ko.dataFor($('#main').get(0)).deal_id(object.id)
      ko.dataFor($('#main').get(0)).deal_tag(object.tag)
      ko.cleanNode($('#container_selection').get(0))
      $('#container_selection').remove()
      $('#main').show()

    generateItemsUrl: (object) => "/deals/#{object.id}/rules.json"

    generateChildrenParams: (object) => {}

    createChildrenViewModel: (data, params, object) =>
      new DealRulesViewModel(data, params, object)

  class self.DealRulesViewModel extends FolderViewModel
    constructor: (data, params, object) ->
      @url = "/deals/#{object.id}/rules.json"
      super(data)

      @params =
        page: @page
        per_page: @per_page
