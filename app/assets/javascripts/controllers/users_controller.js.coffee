$ ->
  class self.UsersController extends self.ApplicationController
    index: =>
      self.application.path('users')
      $.getJSON('/users/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("users_data")
        self.application.object(new UsersViewModel(objects))
      )

    new: =>
      self.application.path('users/preview')
      $.getJSON("/users/new.json", {}, (object) ->
        toggleSelect("users_new")
        self.application.object(new UserViewModel(object))
      )

    show: =>
      self.application.path('users/preview')
      $.getJSON("users/#{this.params.id}.json", {}, (object) ->
        toggleSelect("users_data")
        self.application.object(new UserViewModel(object, true))
      )
