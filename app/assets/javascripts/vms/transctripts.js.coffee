$ ->
  class self.TranscriptViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/transcripts/data.json'
      @date_from = ko.observable(new Date())
      @date_to = ko.observable(new Date())
      @deal_id = ko.observable()
      @deal_tag = ko.observable()

      unless $.isEmptyObject(params)
        @deal_id(params.deal_id)
        @date_from($.datepicker.parseDate('yy-mm-dd', params.date_from))
        @date_to($.datepicker.parseDate('yy-mm-dd', params.date_to))
        @deal_tag(data.deal.tag) if data.deal

      @parse_date_from = ko.observable(
        $.datepicker.formatDate('yy-mm-dd', @date_from()))
      @parse_date_to = ko.observable(
        $.datepicker.formatDate('yy-mm-dd', @date_to()))
      @from = ko.observable(ko.mapping.fromJS(data.from))
      @to = ko.observable(ko.mapping.fromJS(data.to))
      @totals = ko.observable(ko.mapping.fromJS(data.totals))
      @mu = ko.observable('natural')

      super(data)

      @params =
        date_from: @date_from().toString()
        date_to: @date_to().toString()
        deal_id: @deal_id()
        page: @page
        per_page: @per_page

      @date_from.subscribe(@filter)
      @date_to.subscribe(@filter)
      @deal_id.subscribe(@filter)

    filter: =>
      @parse_date_from($.datepicker.formatDate('yy-mm-dd', @date_from()))
      @parse_date_to($.datepicker.formatDate('yy-mm-dd', @date_to()))
      @params =
        date_from: @date_from().toString()
        date_to: @date_to().toString()
        deal_id: @deal_id()
        page: @page
        per_page: @per_page
      @filterData()

    onDataReceived: (data) =>
      @from(ko.mapping.fromJS(data.from))
      @to(ko.mapping.fromJS(data.to))
      @totals(ko.mapping.fromJS(data.totals))


    selectDeals: =>
      $('<div id="container_selection"></div>').insertAfter('#main')
      $('#main').hide()

      $.get("/deals", selection: true, (form) ->
        $.getJSON("/deals/data.json", {}, (data) ->
          $('#container_selection').html(form)
          ko.applyBindings(new DealsViewModel(data, true),
            $('#container_selection').get(0))
        )
      )

    selectTranscript: (object) =>
      @deal_tag(object.account)
      @deal_id(object.deal_id)
