ko.bindingHandlers.datepicker =
  init: (element, valueAccessor) ->
    $(element).datepicker($.datepicker.
    regional[I18n.locale])
    if valueAccessor().maxDate?
      $(element).datepicker( "option", "maxDate", ko.utils.unwrapObservable(valueAccessor().maxDate))
    else if valueAccessor().minDate?
      $(element).datepicker( "option", "minDate", ko.utils.unwrapObservable(valueAccessor().minDate))

    ko.utils.registerEventHandler(element, "change", ->
      observable = valueAccessor().value
      observable($(element).datepicker("getDate"))
    )
    ko.utils.domNodeDisposal.addDisposeCallback(element, ->
      $(element).datepicker("destroy")
    )
  update: (element, valueAccessor) ->
    value = ko.utils.unwrapObservable(valueAccessor().value)
    current = $(element).datepicker("getDate")
    value = new Date(value) if typeof value == "string"
    unless(value - current == 0)
      $(element).datepicker("setDate", value)
