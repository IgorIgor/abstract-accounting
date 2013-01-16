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
        if allBindings().value?
          allBindings().value(ui.item.data[config.value])
        bind = null
        bind = config.bind if config.hasOwnProperty("bind")
        for key, value of ui.item.data
          if bind and bind.hasOwnProperty(key)
            if typeof value == "object"
              for key2, value2 of value
                if bind[key].hasOwnProperty(key2)
                  if $.isArray(bind[key][key2])
                    bind_value(value2) for bind_value in bind[key][key2]
                  else
                    bind[key][key2](value2)
            else
              bind[key](value)
          else if (viewModel.hasOwnProperty(key))
            viewModel[key](value)

        config.afterChange() if config.afterChange
      )

      $(element).data('autocomplete')._resizeMenu = () ->
        ul = this.menu.element
        ul.outerWidth(this.element.outerWidth())

      if allBindings().value?
        allBindings().value.subscribe( ->
          if config.hasOwnProperty("bind")
            bind = config.bind
            for key, value of bind
              if typeof value == "object"
                for key2, value2 of value
                  if $.isArray(value2)
                    bind_value(null) for bind_value in value2
                  else
                    value2(null)
              else
                value(null)
        )
      else
        $(element).bind('autocompletechange', (e, ui) ->
          if !ui.item
            if config.hasOwnProperty("bind")
              bind = config.bind
              for key, value of bind
                if typeof value == "object"
                  for key2, value2 of value
                    if $.isArray(value2)
                      bind_value(null) for bind_value in value2
                    else
                      value2(null)
                else
                  value(null)
            if config.onlySelect
              if allBindings().value?
                allBindings().value('')
              else
                $(element).val('')
              config.afterChange() if config.afterChange
        )
