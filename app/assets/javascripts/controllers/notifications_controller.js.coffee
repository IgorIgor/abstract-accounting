$ ->
  class self.NotificationsController extends self.ApplicationController
    index: =>
      self.application.path('notifications')
      $.getJSON('/notifications/data.json', normalizeHash(this.params.toHash()), (objects) ->
        toggleSelect("notifications_data")
        self.application.object(new NotificationsViewModel(objects))
      )

    new: ->
      self.application.path('notifications/preview')
      $.getJSON("/notifications/new.json", {}, (object) ->
        toggleSelect("notifications_new")
        self.application.object(new NotificationViewModel(object))
      )

    show: ->
      self.application.path('notifications/preview')
      $.getJSON("notifications/#{this.params.id}.json", {}, (object) ->
        toggleSelect("notifications_data")
        self.application.object(new NotificationViewModel(object, true))
      )
