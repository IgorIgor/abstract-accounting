$ ->
  self.notification = ->
    true

  notification()

  class self.NotificationViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'notifications', readonly)
