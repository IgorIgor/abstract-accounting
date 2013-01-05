$ ->
  class self.EstimateCatalogViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'catalogs', readonly)
      @namespace = "estimate"

      @with_document = ko.observable(object.have_document)

      if object.catalog.parent_id
        @params =
          parent_id: object.catalog.parent_id

    edit: =>
      @readonly(false)
      @disable(false)
      @method = 'PUT'
      location.hash = "##{@namespace}/#{@route}/#{@object.id()}/edit"

    save: =>
      @disable(true)
      url = "/#{@namespace}/#{@route}"
      if @method == 'PUT'
        url = "/#{@namespace}/#{@route}/#{@object.id()}"
      @ajaxRequest(@method, url, normalizeHash(ko.mapping.toJS(@object)))
