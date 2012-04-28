ko.bindingHandlers.tabs =
  init: (element, valueAccessor) ->
    currIndex = valueAccessor().current

    $($(element).find('ul li a').get(currIndex)).addClass('current')
    $($(element).find('div.tab').get(currIndex)).addClass('current')

    $(element).find('ul li a').each( ->
      $(this).click ->
        currIndex = $(element).find('ul li a').index($(this))

        $(element).find('ul li a').each( -> $(this).removeClass('current'))
        $(element).find('div.tab').each( -> $(this).removeClass('current'))

        $($(element).find('ul li a').get(currIndex)).addClass('current')
        $($(element).find('div.tab').get(currIndex)).addClass('current')
    )
