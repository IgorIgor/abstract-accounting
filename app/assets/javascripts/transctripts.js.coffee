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
      @from_debit = ko.observable(data.from_debit)
      @from_credit = ko.observable(data.from_credit)
      @to_debit = ko.observable(data.to_debit)
      @to_credit = ko.observable(data.to_credit)
      @total_debits = ko.observable(data.total_debits)
      @total_credits = ko.observable(data.total_credits)
      @total_debits_diff = ko.observable(data.total_debits_diff)
      @total_credits_diff = ko.observable(data.total_credits_diff)

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
        @from_debit(data.from_debit)
        @from_credit(data.from_credit)
        @to_debit(data.to_debit)
        @to_credit(data.to_credit)
        @total_debits(data.total_debits)
        @total_credits(data.total_credits)
        @total_debits_diff(data.total_debits_diff)
        @total_credits_diff(data.total_credits_diff)
      )
