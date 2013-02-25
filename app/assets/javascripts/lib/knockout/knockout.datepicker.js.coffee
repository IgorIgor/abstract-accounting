ko.bindingHandlers.datepicker =
  init: (element, valueAccessor) ->
    $(element).datepicker($.datepicker.regional[I18n.locale])
    $(element).datepicker( "option", "dateFormat", "yy-mm-dd")
    if valueAccessor().maxDate?
      $(element).datepicker( "option", "maxDate", ko.utils.unwrapObservable(valueAccessor().maxDate))
    else if valueAccessor().minDate?
      $(element).datepicker( "option", "minDate", ko.utils.unwrapObservable(valueAccessor().minDate))
    ko.utils.registerEventHandler(element, "change", ->
      observable = valueAccessor().value
      observable($.datepicker.formatDate("yy-mm-dd", $(element).datepicker("getDate")))
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

ko.bindingHandlers.monthpicker =
  init: (element, valueAccessor) ->
    $(element).datepicker($.datepicker.regional[I18n.locale])
    $(element).datepicker('option', {
      changeMonth: true,
      gotoCurrent: true,
      changeYear: true,
      dateFormat: 'mm/yy',
      showButtonPanel: true,
      yearRange: "1980:#{new Date().getFullYear()}",
      onClose: (dateText, inst) =>
        observable = valueAccessor().value
        value = new Date(inst.selectedYear, inst.selectedMonth)
        observable(value)
      }
    )
    ko.utils.domNodeDisposal.addDisposeCallback(element, ->
      $('#ui-datepicker-div').removeClass('hiden')
      $(element).datepicker("destroy")
    )
  update: (element, valueAccessor) ->
    $('#ui-datepicker-div').addClass('hiden')
    value = ko.utils.unwrapObservable(valueAccessor().value)
    current = $(element).datepicker("getDate")
    value = new Date(value) if typeof value == "string"
    unless(value - current == 0)
      $(element).datepicker('setDate', value)

