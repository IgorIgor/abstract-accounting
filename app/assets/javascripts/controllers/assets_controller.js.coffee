$ ->
  class self.AssetsController extends self.ApplicationController
    new: ->
      self.application.path('assets/preview')
      $.getJSON("/assets/new.json", {}, (object) ->
        toggleSelect("assets_new")
        self.application.object(new AssetViewModel(object))
      )

    show: ->
      self.application.path('assets/preview')
      $.getJSON("assets/#{this.params.id}.json", {}, (object) ->
        self.application.object(new AssetViewModel(object, true))
      )
