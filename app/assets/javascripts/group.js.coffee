$ ->
  class self.GroupViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'groups', readonly)

    addUser: =>
      @object.users.push(id: ko.observable(), tag: ko.observable())

    deleteUser: (user) =>
      @object.users.remove(user)
