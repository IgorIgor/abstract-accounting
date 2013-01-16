ko.bindingHandlers.polymorphic_checked =
  init: (element, valueAccessor) ->
    updateHandler = ->
      modelValue = valueAccessor()
      unwrappedValue = ko.utils.unwrapObservable(modelValue)
      existingEntryIndex = -1
      $.each(unwrappedValue, (idx,item) =>
         if ((item['id'] == element.value) && (item['type'] == $(element).data('itemType')))
             existingEntryIndex = idx
      )
      if (element.checked && (existingEntryIndex < 0))
        modelValue.push({id: element.value, type: $(element).data('itemType')})
      else if ((!element.checked) && (existingEntryIndex >= 0))
        modelValue.splice(existingEntryIndex, 1)
    ko.utils.registerEventHandler(element, "click", updateHandler)

  update: (element, valueAccessor) ->
      value = ko.utils.unwrapObservable(valueAccessor());
      $.each(value, (idx,item) =>
          if ((item['id'] == element.value) && (item['type'] == $(element).data('itemType')))
              element.checked = true
      )
