$ ->
  class self.EstimateCatalogsViewModel extends FolderViewModel
    @__data_url = '/estimate/catalogs/data.json'

    constructor: (data, canSelect = false) ->
      @url = '/estimate/catalogs/data.json'
      @canSelect = ko.observable(canSelect)
      @parents = ko.observableArray([{id: null, tag: I18n.t("views.estimates.catalogs.root")}])

      super(data)

      @params =
        page: @page
        per_page: @per_page

    selectItem: (object) =>
      @parents.push(object)
      @params["parent_id"] = object.id
      @filterData()

    selectParent: (object) =>
      index = @parents().indexOf(object)
      @parents(@parents().slice(0, index+1))
      @params["parent_id"] = object.id
      @filterData()

    newCatalog: =>
      if @params["parent_id"]
        param = "?#{$.param(parent_id: @params["parent_id"])}"
      else
        param = ""
      location.hash = "estimate/catalogs/new#{param}"

    showDocument: (object) =>
      url = location.protocol + "//" + location.host + "/estimate/catalogs/#{object.id}/document"
      window.open(url, "_blank")

    showBoMs: (object) =>
      location.hash = "estimate/bo_ms?#{$.param(catalog_id: object.id)}"

    showPrices: (object) =>
      location.hash = "estimate/prices?#{$.param(catalog_id: object.id)}"

  class self.DialogCatalogsViewModel extends EstimateCatalogsViewModel
    constructor: (data) ->
      @filter =
        tag: ko.observable('')
      super(data)

    @include DialogsHelper
