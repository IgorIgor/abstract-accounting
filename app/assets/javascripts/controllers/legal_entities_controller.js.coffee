$ ->
  class self.LegalEntitiesController extends self.ApplicationController
    new: ->
      self.application.path('legal_entities/preview')
      $.getJSON("/legal_entities/new.json", {}, (object) ->
        toggleSelect("legal_entities_new")
        self.application.object(new LegalEntityViewModel(object))
      )

    show: ->
      self.application.path('legal_entities/preview')
      $.getJSON("legal_entities/#{this.params.id}.json", {}, (object) ->
        toggleSelect("entities_data")
        self.application.object(new LegalEntityViewModel(object, true))
      )
