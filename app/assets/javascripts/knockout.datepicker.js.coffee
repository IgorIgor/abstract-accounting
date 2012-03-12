ko.bindingHandlers.datepicker =
  init: (element, valueAccessor, allBindingsAccessor) ->
    options = allBindingsAccessor().datepickerOptions || {}
    $(element).datepicker(options)

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
    unless(value - current == 0)
      $(element).datepicker("setDate", value)
