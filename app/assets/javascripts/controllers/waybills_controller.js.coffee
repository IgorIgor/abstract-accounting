$ ->
  class self.WaybillsController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      if filter.view? and filter.view == "table"
        self.application.path('waybills/list')
        $.getJSON('/waybills/list.json', normalizeHash(filter), (objects) ->
          toggleSelect("waybills_data")
          self.application.object(new WaybillsListViewModel(objects))
        )
      else
        self.application.path('waybills')
        $.getJSON('/waybills/data.json', normalizeHash(filter), (objects) ->
          toggleSelect("waybills_data")
          self.application.object(new WaybillsViewModel(objects))
        )

    new: ->
      self.application.path('waybills/preview')
      $.getJSON("/waybills/new.json", {}, (object) ->
        toggleSelect("waybills_new")
        self.application.object(new WaybillViewModel(object))
      )

    show: ->
      self.application.path('waybills/preview')
      $.getJSON("waybills/#{this.params.id}.json", {}, (object) ->
        toggleSelect("waybills_data")
        self.application.object(new WaybillViewModel(object, true))
      )
