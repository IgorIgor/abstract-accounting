$ ->
  class self.GroupViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, '/groups', readonly)

    addUser: =>
      @object.users.push(id: ko.observable())

    deleteUser: (user) =>
      @object.users.remove(user)