$ ->
  class self.GroupsController extends self.ApplicationController
    index: =>
      self.application.path('groups')
      $.getJSON('/groups/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("groups_data")
        self.application.object(new GroupsViewModel(objects))
      )

    new: ->
      self.application.path('groups/preview')
      $.getJSON("/groups/new.json", {}, (object) ->
        toggleSelect("groups_new")
        self.application.object(new GroupViewModel(object))
      )

    show: ->
      self.application.path('groups/preview')
      $.getJSON("groups/#{this.params.id}.json", {}, (object) ->
        toggleSelect("groups_data")
        self.application.object(new GroupViewModel(object, true))
      )
