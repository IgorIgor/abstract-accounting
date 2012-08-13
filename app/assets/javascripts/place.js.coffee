$ ->
  class self.PlaceViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'places', readonly)
