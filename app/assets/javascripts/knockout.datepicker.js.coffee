ko.bindingHandlers.datepicker =
  init: (element, valueAccessor) ->
    $(element).datepicker($.datepicker.
    regional[I18n.locale])
    $( element ).datepicker( "option", "maxDate", "+0" );

    ko.utils.registerEventHandler(element, "change", ->
      observable = valueAccessor()
      observable($(element).datepicker("getDate"))
    )
    ko.utils.domNodeDisposal.addDisposeCallback(element, ->
      $(element).datepicker("destroy")
    )
  update: (element, valueAccessor) ->
    value = ko.utils.unwrapObservable(valueAccessor())
    current = $(element).datepicker("getDate")
    value = new Date(value) if typeof value == "string"
    unless(value - current == 0)
      $(element).datepicker("setDate", value)
