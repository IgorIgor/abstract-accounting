$ ->
  class self.DealsController extends self.ApplicationController
    index: =>
      self.application.path('deals')
      $.getJSON('/deals/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("deals_data")
        self.application.object(new DealsViewModel(objects))
      )

    new: ->
      self.application.path('deals/preview')
      $.getJSON("/deals/new.json", {}, (object) ->
        toggleSelect("deals_new")
        self.application.object(new DealViewModel(object))
      )

    show: ->
      self.application.path('deals/preview')
      $.getJSON("deals/#{this.params.id}.json", {}, (object) ->
        toggleSelect("deals_data")
        self.application.object(new DealViewModel(object, true))
      )
