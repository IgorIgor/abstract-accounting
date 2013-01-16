$ ->
  class self.QuoteViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'quote', readonly)
