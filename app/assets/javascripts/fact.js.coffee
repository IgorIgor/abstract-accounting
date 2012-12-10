$ ->
  class self.FactViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'facts', readonly)
