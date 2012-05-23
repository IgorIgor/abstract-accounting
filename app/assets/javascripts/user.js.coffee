$ ->
  class self.UserViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, '/users', readonly)
