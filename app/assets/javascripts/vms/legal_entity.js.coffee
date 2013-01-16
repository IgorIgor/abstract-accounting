$ ->
  class self.LegalEntityViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'legal_entities', readonly)
