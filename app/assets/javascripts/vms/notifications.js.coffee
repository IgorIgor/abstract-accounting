$ ->
  class self.NotificationsViewModel extends TreeViewModel
    constructor: (data) ->
      @url = '/notifications/data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

    getType: (object) ->
      'notifications'
