$ ->
  class self.PriceViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'estimate/prices', readonly)

    namespace: =>
      ""
