$ ->
  class self.MoneyController extends self.ApplicationController
    new: ->
      self.application.path('money/preview')
      $.getJSON("/money/new.json", {}, (object) ->
        toggleSelect("money_new")
        self.application.object(new MoneyViewModel(object))
      )

    show: ->
      self.application.path('money/preview')
      $.getJSON("money/#{this.params.id}.json", {}, (object) ->
        self.application.object(new MoneyViewModel(object, true))
      )
