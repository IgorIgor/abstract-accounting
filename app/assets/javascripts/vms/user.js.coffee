$ ->
  class self.UserViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'users', readonly)
      @change_password = ko.observable(!object.id?)

    addCredential: =>
      @object.credentials.push(tag: ko.observable(), document_type: null)

    deleteCredential: (credential) =>
      @object.credentials.remove(credential)

  class self.UsersViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/users/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page

    showUser: (object) ->
      location.hash = "documents/users/#{object.id}"
