$ ->
  class self.FactsController extends self.ApplicationController
    new: ->
      self.application.path('facts/preview')
      $.getJSON("/facts/new.json", {}, (object) ->
        toggleSelect("facts_new")
        self.application.object(new FactViewModel(object))
      )

    show: ->
      self.application.path('facts/preview')
      $.getJSON("facts/#{this.params.id}.json", {}, (object) ->
        self.application.object(new FactViewModel(object, true))
      )
