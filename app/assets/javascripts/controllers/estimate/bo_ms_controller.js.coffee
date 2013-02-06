$ ->
  class self.BoMsController extends self.ApplicationController
    new: =>
      @render 'estimate/bo_ms/preview'
      $.getJSON("estimate/bo_ms/new.json", {}, (object) ->
        toggleSelect("estimate_bo_ms_new")
        self.application.object(new BoMViewModel(object))
      )

    show: =>
      @render 'estimate/bo_ms/preview'
      $.getJSON("estimate/bo_ms/#{this.params.id}.json", {}, (object) ->
        self.application.object(new BoMViewModel(object, true))
      )
