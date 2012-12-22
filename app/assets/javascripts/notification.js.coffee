$ ->
  self.sticker = (item) ->
    stick = $.sticky(item.html)
    $("##{stick.id} > .sticky-close").click( =>
      $.ajax(
        type:'POST'
        url: '/notifications/hide'
        data: { id: item.id }
      )
    )
    $("##{stick.id} a#link").click( =>
      $("##{stick.id} > .sticky-close").click()
    )
    $("##{stick.id}").addClass('warning') if item.notification_type == 2

  self.notification = ->
    $.ajax(
      type:'GET'
      url: '/notifications/check'
      data: {}
      complete: (data) =>
        response = JSON.parse(data.responseText)
        if response.show
          $.each(response.notifications, (idx, item) ->
            found = ko.utils.arrayFirst($("div.sticky:visible a#link"), (a) =>
              $(a).data('itemId') == item.id
            )
            sticker(item) unless found
          )
    )

  notification()
  setInterval ( -> notification()), 60000

  class self.NotificationViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'notifications', readonly)
