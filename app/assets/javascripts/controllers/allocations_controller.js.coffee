$ ->
  class self.AllocationsController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      toggleSelect("allocations_data")
      if filter.view? and filter.view == "table"
        @render 'allocations/list'
        $.getJSON('/allocations/list.json', normalizeHash(filter), (objects) ->
          self.application.object(new AllocationsListViewModel(objects))
        )
      else
        @render 'allocations'
        $.getJSON('/allocations/data.json', normalizeHash(filter), (objects) ->
          self.application.object(new AllocationsViewModel(objects))
        )

    new: =>
      @render 'allocations/preview'
      toggleSelect("allocations_new")
      $.getJSON("/allocations/new.json", {}, (object) ->
        self.application.object(new AllocationViewModel(object))
      )

    show: =>
      @render 'allocations/preview'
      toggleSelect("allocations_data")
      $.getJSON("allocations/#{this.params.id}.json", {}, (object) ->
        self.application.object(new AllocationViewModel(object, true))
      )
