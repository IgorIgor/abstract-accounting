$ ->
  class self.MoneyViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'money', readonly)
