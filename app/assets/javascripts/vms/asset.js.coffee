$ ->
  class self.AssetViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'assets', readonly)
