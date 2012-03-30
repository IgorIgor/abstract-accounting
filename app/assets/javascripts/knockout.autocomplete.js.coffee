ko.bindingHandlers.autocomplete =
  init: (element, valueAccessor, allBindings, viewModel) ->
    config = valueAccessor()
    config.dataType = 'json' unless config.dataType

    $(element).autocomplete(config)

    config.search = (term) ->
      if $(element).autocomplete('widget').is(':visible')
        $(element).autocomplete('close')
        return
      $(element).addClass('searching')
      $(element).autocomplete('search', term)
      $(element).focus()

    if config.parse == undefined && config.value
      $(element).data('autocomplete')._renderItem = (ul, item) ->
        return $('<li>')
               .data('item.autocomplete', { data: item, value: item[config.value] })
               .append("<a>#{item[config.value]}</a>").appendTo(ul)

      $(element).bind('autocompleteselect', (_, ui) ->
        config.bindId(ui.item.data.id)
        for key, value of ui.item.data
          viewModel[key](value) if (viewModel.hasOwnProperty(key))
      )

      $(element).data('autocomplete')._resizeMenu = () ->
        ul = this.menu.element
        ul.outerWidth(this.element.outerWidth())
