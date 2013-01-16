$ ->
  class self.PlacesController extends self.ApplicationController
    index: =>
      self.application.path('places')
      $.getJSON('/places/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("places_data")
        self.application.object(new PlacesViewModel(objects))
      )

    new: =>
      self.application.path('places/preview')
      $.getJSON("/places/new.json", {}, (object) ->
        toggleSelect("places_new")
        self.application.object(new PlaceViewModel(object))
      )

    show: =>
      self.application.path('places/preview')
      $.getJSON("places/#{this.params.id}.json", {}, (object) ->
        self.application.object(new PlaceViewModel(object, true))
      )
