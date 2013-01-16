$ ->
  class self.EntitiesController extends self.ApplicationController
    index: =>
      self.application.path('entities')
      $.getJSON('/entities/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("entities_data")
        self.application.object(new EntitiesViewModel(objects))
      )

    new: ->
      self.application.path('entities/preview')
      $.getJSON("/entities/new.json", {}, (object) ->
        toggleSelect("entities_new")
        self.application.object(new EntityViewModel(object))
      )

    show: ->
      self.application.path('entities/preview')
      $.getJSON("entities/#{this.params.id}.json", {}, (object) ->
        toggleSelect("entities_data")
        self.application.object(new EntityViewModel(object, true))
      )
