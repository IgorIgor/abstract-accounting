$ ->
  class self.EntityViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'entities', readonly)
