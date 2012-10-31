$ ->
  self.notification = ->
    $.ajax(
      type:'GET'
      url: '/notifications/check'
      data: {}
      complete: (data) =>
        response = JSON.parse(data.responseText)
        if response.show
          $.sticky(response.html)
          $('.sticky-close').click( =>
            $.ajax(
              type:'POST'
              url: '/notifications/hide'
            )
          )
          $('a#link').click( =>
            $('.sticky-close').click()
          )
    )
  notification()
