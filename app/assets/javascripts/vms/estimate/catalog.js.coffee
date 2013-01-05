$ ->
  class self.EstimateCatalogViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/catalogs', readonly)

      @with_document = ko.observable(object.have_document)

      if object.catalog.parent_id
        @params =
          parent_id: object.catalog.parent_id

    namespace: =>
      ""
