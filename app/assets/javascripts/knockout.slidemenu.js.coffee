ko.bindingHandlers.slidemenu =
  init: (element, valueAccessor) ->
    list = $(element).find('ul')

    $(element).click ->
      list.slideToggle('fast')

    $(document).click (e) ->
      unless (e.target.id == valueAccessor()) || (list.css('display') == 'none')
        list.slideUp('fast')
