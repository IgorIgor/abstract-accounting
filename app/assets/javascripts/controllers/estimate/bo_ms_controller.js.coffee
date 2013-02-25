$ ->
  class self.BoMsController extends self.ApplicationController
    index: =>
      @render 'estimate/bo_ms'
      $.getJSON('estimate/bo_ms/data.json', normalizeHash(this.params.toHash()), (objects) =>
        toggleSelect("estimate_bo_ms_data")
        self.application.object(new EstimateBomsViewModel(objects, this.params.toHash()))
      )

    new: =>
      @render 'estimate/bo_ms/preview'
      $.getJSON("estimate/bo_ms/new.json", {}, (object) ->
        toggleSelect("estimate_bo_ms_new")
        self.application.object(new BoMViewModel(object))
      )

    show: =>
      @render 'estimate/bo_ms/preview'
      $.getJSON("estimate/bo_ms/#{this.params.id}.json", {}, (object) ->
        toggleSelect("estimate_bo_ms_data")
        self.application.object(new BoMViewModel(object, true))
      )
