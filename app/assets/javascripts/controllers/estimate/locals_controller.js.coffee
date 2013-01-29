$ ->
  class self.LocalsController extends self.ApplicationController
    new: =>
      @render 'estimate/locals/preview'
      $.getJSON("estimate/locals/new.json", {}, (object) ->
        self.application.object(new EstimateLocalViewModel(object))
      )

    show: =>
      @render 'estimate/locals/preview'
      $.getJSON("estimate/locals/#{this.params.id}.json", {}, (object) ->
        self.application.object(new EstimateLocalViewModel(object, true))
      )
