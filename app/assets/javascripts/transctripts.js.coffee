$ ->
  class self.TranscriptViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/transcripts/data.json'
      @deal = ko.observable()
      @date_from = ko.observable(new Date())
      @parse_date_from = ko.observable(
        $.datepicker.formatDate('yy-mm-dd', @date_from()))
      @date_to = ko.observable(new Date())
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
        deal_id: @deal()
        page: @page
        per_page: @per_page

      @deal.subscribe(@filter)
      @date_from.subscribe(@filter)
      @date_to.subscribe(@filter)

    filter: =>
      @parse_date_from($.datepicker.formatDate('yy-mm-dd', @date_from()))
      @parse_date_to($.datepicker.formatDate('yy-mm-dd', @date_to()))
      @params =
        date_from: @date_from().toString()
        date_to: @date_to().toString()
        deal_id: @deal()
        page: @page
        per_page: @per_page
      $.getJSON(@url, @params, (data) =>
        @documents(data.objects)
        @page(1)
        @count(data.count)
        @range(@rangeGenerate())
        @from(ko.mapping.fromJS(data.from))
        @to(ko.mapping.fromJS(data.to))
        @totals(ko.mapping.fromJS(data.totals))
      )
