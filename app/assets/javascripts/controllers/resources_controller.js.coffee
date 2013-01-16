$ ->
  class self.ResourcesController extends self.ApplicationController
    index: =>
      self.application.path('resources')
      $.getJSON('/resources/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("resources_data")
        self.application.object(new ResourcesViewModel(objects))
      )
