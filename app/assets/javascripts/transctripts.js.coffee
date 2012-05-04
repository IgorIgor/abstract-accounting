$ ->
  class self.TranscriptViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/transcripts/data.json'
      @deal = ko.observable()
      @date_from = ko.observable(new Date())
      @date_to = ko.observable(new Date())
      data.objects = data

      super(data)

      @params =
        date_from: @date_from().toString()
        date_to: @date_to().toString()
        deal_id: @deal()

      @deal.subscribe(@filter)
      @date_from.subscribe(@filter)
      @date_to.subscribe(@filter)

    filter: =>
      @params =
        date_from: @date_from().toString()
        date_to: @date_to().toString()
        deal_id: @deal()
      $.getJSON(@url, @params, (data) =>
        @documents(data)
      )
