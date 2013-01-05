$ ->
  class self.CatalogsController extends self.ApplicationController
    index: =>
      @render 'estimate/catalogs'
      $.getJSON('estimate/catalogs/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("estimate_catalogs_data")
        self.application.object(new EstimateCatalogsViewModel(objects))
      )

    new: =>
      @render 'estimate/catalogs/preview'
      $.getJSON("estimate/catalogs/new.json", normalizeHash(this.params.toHash()), (object) ->
        toggleSelect("estimate_catalogs_data")
        self.application.object(new EstimateCatalogViewModel(object))
      )

    show: =>
      @render 'estimate/catalogs/preview'
      $.getJSON("estimate/catalogs/#{this.params.id}.json", {}, (object) ->
        toggleSelect("estimate_catalogs_data")
        self.application.object(new EstimateCatalogViewModel(object, true))
      )
