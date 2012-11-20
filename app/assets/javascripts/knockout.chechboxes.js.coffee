ko.bindingHandlers.polymorphic_checked =
  init: (element, valueAccessor) ->
    updateHandler = ->
      modelValue = valueAccessor()
      unwrappedValue = ko.utils.unwrapObservable(modelValue)
      existingEntryIndex = -1
      $.each(unwrappedValue, (idx,item) =>
         if ((item['id'] == element.value) && (item['type'] == element.getAttribute('itemtype')))
             existingEntryIndex = idx
      )
      if (element.checked && (existingEntryIndex < 0))
        modelValue.push({id: element.value, type: element.getAttribute('itemtype')})
      else if ((!element.checked) && (existingEntryIndex >= 0))
        modelValue.splice(existingEntryIndex, 1)
    ko.utils.registerEventHandler(element, "click", updateHandler)

  update: (element, valueAccessor) ->
      value = ko.utils.unwrapObservable(valueAccessor());
      $.each(value, (idx,item) =>
          if ((item['id'] == element.value) && (item['type'] == element.getAttribute('itemtype')))
              element.checked = true
      )
