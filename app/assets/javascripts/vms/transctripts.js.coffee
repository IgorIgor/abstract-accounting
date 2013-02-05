$ ->
  class self.TranscriptViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/transcripts/data.json'
      @date_from = ko.observable(new Date())
      @date_to = ko.observable(new Date())
      @deal_id = ko.observable()
      @deal_tag = ko.observable()

      @dialog_deals = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

      unless $.isEmptyObject(params)
        @deal_id(params.deal_id)
        @date_from($.datepicker.parseDate('yy-mm-dd', params.date_from))
        @date_to($.datepicker.parseDate('yy-mm-dd', params.date_to))
      @deal_tag(data.deal.tag) if data.deal?.tag?

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

    selectTranscript: (object) =>
      if object.deal_id
        @deal_tag(object.account)
        @deal_id(object.deal_id)

    select: (object) =>
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'deals_selector'
        $.getJSON('deals/data.json', {}, (data) =>
          @dialog_deals(new TranscriptDealsViewModel(data))
        )

  class self.TranscriptDealsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'deals/data.json'
      @filter =
        tag: ko.observable('')

      super(data)

    select: (object)->
      self.application.object().select(object)
