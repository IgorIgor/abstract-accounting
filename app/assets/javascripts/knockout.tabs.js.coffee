ko.bindingHandlers.tabs =
  init: (element, valueAccessor, allBindingAccessor) ->
    currIndex = valueAccessor().current
    disabled = valueAccessor().disable
    if valueAccessor().headers
      headers = ko.utils.unwrapObservable(valueAccessor().headers)
      $.each(headers,(idx, value) ->
        if idx == currIndex && allBindingAccessor().value
            allBindingAccessor().value(value.id)
        $('ul#head').append("<li><a tab-id='"+value.id+"'>"+value.name+"</a></li>")
      )

    $($(element).find('ul li a').get(currIndex)).addClass('current')
    $($(element).find('div.tab').get(currIndex)).addClass('current')
    if valueAccessor().change
      valueAccessor().change()

    $(element).find('ul li a').each( ->
      $(this).click ->
        unless disabled()
          currIndex = $(element).find('ul li a').index($(this))

          $(element).find('ul li a').each( -> $(this).removeClass('current'))
          $(element).find('div.tab').each( -> $(this).removeClass('current'))

          $($(element).find('ul li a').get(currIndex)).addClass('current')
          $($(element).find('div.tab').get(currIndex)).addClass('current')
          if allBindingAccessor().value
            allBindingAccessor().value($(this).attr('tab-id'))
          if valueAccessor().change
            valueAccessor().change()
    )
ko.bindingHandlers.jqTabs =
  init: (element, valueAccessor, allBindingAccessor) ->
    currIndex = valueAccessor().current
    if valueAccessor().headers
      headers = ko.utils.unwrapObservable(valueAccessor().headers)
    $.each(headers,(idx, value) ->
      if idx == currIndex && allBindingAccessor().value
        allBindingAccessor().value(value.id)
      $('ul#head').append("<li><a href='##{idx+1}' tab-id='#{value.id}'>#{value.name}</a></li>")
    )
    valueAccessor().tabSelect()

    $(element).tabs({
      scrollable: true,
      changeOnScroll: false,
      closable: true
      select:(event,ui) ->
        $('li.ui-tabs-selected').removeClass('ui-tabs-selected ui-state-active')
        allBindingAccessor().value($(ui.tab).attr('tab-id'))
        $(ui.tab).parent().addClass('ui-tabs-selected ui-state-active')
        valueAccessor().tabSelect()
        event.preventDefault()
    })
