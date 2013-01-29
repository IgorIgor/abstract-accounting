$ ->
  class self.PricesController extends self.ApplicationController
    index: =>
      @render 'estimate/prices'
      $.getJSON('estimate/prices/data.json', normalizeHash(this.params.toHash()), (objects) =>
        toggleSelect("estimate_prices_data")
        self.application.object(new EstimatePricesViewModel(objects, this.params.toHash()))
      )

    new: =>
      @render 'estimate/prices/preview'
      $.getJSON("estimate/prices/new.json", {}, (object) ->
        toggleSelect("estimate_prices_new")
        self.application.object(new EstimatePriceViewModel(object))
      )

    show: =>
      @render 'estimate/prices/preview'
      $.getJSON("estimate/prices/#{this.params.id}.json", {}, (object) ->
        toggleSelect("estimate_prices_data")
        self.application.object(new EstimatePriceViewModel(object, true))
      )
