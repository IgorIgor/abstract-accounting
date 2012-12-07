ko.bindingHandlers.jqTabs =
  init: (element, valueAccessor, allBindingAccessor) ->
    currIndex = valueAccessor().current
    disabled = if valueAccessor().disable? then valueAccessor().disable else ko.observable(false)
    scrollable = valueAccessor().scrollable
    if valueAccessor().headers
      headers = ko.utils.unwrapObservable(valueAccessor().headers)
      $.each(headers,(idx, value) ->
        if idx == currIndex && allBindingAccessor().value
          allBindingAccessor().value(value.id)
        $('ul#head').append("<li><a href='##{idx+1}' tab-id='#{value.id}'>#{value.name}</a></li>")
      )
    valueAccessor().tabSelect()

    $(element).tabs({
      scrollable: scrollable,
      changeOnScroll: false,
      closable: true,
      selected: currIndex,
      select:(event,ui) ->
        unless disabled()
          $('li.ui-tabs-selected').removeClass('ui-tabs-selected ui-state-active')
          allBindingAccessor().value($(ui.tab).attr('tab-id'))
          $(ui.tab).parent().addClass('ui-tabs-selected ui-state-active')
          valueAccessor().tabSelect()
        event.preventDefault()
    })
