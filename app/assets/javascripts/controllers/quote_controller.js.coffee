$ ->
  class self.QuoteController extends self.ApplicationController
    index: =>
      self.application.path('quote')
      $.getJSON('/quote/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("quote_data")
        self.application.object(new QuotesViewModel(objects))
      )

    new: ->
      self.application.path('quote/preview')
      $.getJSON("/quote/new.json", {}, (object) ->
        toggleSelect("quote_new")
        self.application.object(new QuoteViewModel(object))
      )

    show: ->
      self.application.path('quote/preview')
      $.getJSON("quote/#{this.params.id}.json", {}, (object) ->
        toggleSelect("quote_data")
        self.application.object(new QuoteViewModel(object, true))
      )
