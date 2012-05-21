$ ->
  class self.UserViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, '/users', readonly)
      @id_presence = ko.observable(object.user.id?)
      @change_password = ko.observable(!object.user.id?)

    addCredential: =>
      @object.credentials.push(tag: ko.observable(), document_type: null)

    deleteCredential: (credential) =>
      @object.credentials.remove(credential)

    edit: =>
      @readonly(false)
      @method = 'PUT'
      @id_presence(@object.user.id)
      location.hash = "#documents/users/#{@id()}/edit"

    id: =>
      @object.user.id()
