$ ->
  class self.UserViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, '/users', readonly)

    addCredential: =>
      @object.credentials.push(tag: ko.observable(), doctype: null)

    deleteCredential: (credential) =>
      @object.credentials.remove(credential)
