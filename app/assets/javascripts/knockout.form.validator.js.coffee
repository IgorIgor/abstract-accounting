init_rules = ->
  $("input[rule='required']").each ->
    $(this).rules('add', {
      required: true
      messages: {
        required: "#{$(this).attr('name')} field is required."
      }
    })
  $("input[rule='required_num']").each ->
    $(this).rules('add', {
      required: true
      min: 1
      messages: {
        required: "#{$(this).attr('name')} field is required."
        min: "#{$(this).attr('name')} should be greater than or equal to 1."
      }
    })

ko.bindingHandlers.validate =
  init: (element, valueAccessor) ->
    $(element).submit ->
      $(this).validate({
        errorContainer: '#container_notification'
        errorLabelContainer: '#container_notification ul'
        errorElement: 'li'
      })
      init_rules()
      valueAccessor().success() if $(this).valid()
      false

    $(element).focusin ->
      $(this).valid() if $(this).attr('novalidate')

    $(element).change ->
      $(this).valid() if $(this).attr('novalidate')

ko.bindingHandlers.elementValidate =
  update: (element) ->
    form = $(element).closest('form')
    if form.attr('novalidate')
      init_rules()
      form.valid()
