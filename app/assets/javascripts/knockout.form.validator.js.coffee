$.validator.addMethod('min_strict', (value, el, param) -> value > param )

init_rules = ->
  $("input[rule='required']").each ->
    $(this).rules('add', {
      required: true
      messages: {
        required: "#{$(this).attr('name')} : #{I18n.t('errors.messages.blank')}"
      }
    })
  $("select[rule='required']").each ->
    $(this).rules('add', {
      required: true
      messages: {
        required: "#{$(this).attr('name')} : #{I18n.t('errors.messages.blank')}"
      }
    })
  $("textarea[rule='required']").each ->
    $(this).rules('add', {
      required: true
      messages: {
        required: "#{$(this).attr('name')} : #{I18n.t('errors.messages.blank')}"
      }
    })
  $("input[rule='required_num']").each ->
    $(this).rules('add', {
      required: true
      min_strict: 0
      messages: {
        required: "#{$(this).attr('name')} : #{I18n.t('errors.messages.blank')}"
        min_strict: "#{$(this).attr('name')} : #{I18n.t('errors.messages.greater_than', {count: 0})}"
      }
    })
  $("input[rule='email']").each ->
    $(this).rules('add', {
      required: true
      email: true
      messages: {
        required: "#{$(this).attr('name')} : #{$(this).attr('error-message-required') ? I18n.t('errors.messages.blank')}"
        email: "#{$(this).attr('name')} : #{$(this).attr('error-message-email') ? I18n.t('errors.messages.email')}"
      }
    })
  $("input[rule='min_length']").each ->
    min_length = parseInt($(this).attr('min_length') ? 6)
    $(this).rules('add', {
      required: true
      minlength: min_length
      messages: {
        required: "#{$(this).attr('name')} : #{$(this).attr('error-message-required') ? I18n.t('errors.messages.blank')}"
        minlength: "#{$(this).attr('name')} : #{$(this).attr('error-message-min-length') ? I18n.t('errors.messages.too_short.few')}"
      }
    })
  $("input[rule='equal_to']").each ->
    $(this).rules('add', {
      required: true
      equalTo: "##{$(this).attr('equal_to')}"
      messages: {
        required: "#{$(this).attr('name')} : #{$(this).attr('error-message-required') ? I18n.t('errors.messages.blank')}"
        equalTo: "#{$(this).attr('name')} : #{$(this).attr('error-message-equal-to') ? I18n.t('errors.messages.equal_to')}"
      }
    })
  $("input[rule~='digits']").each ->
    $(this).rules('add', {
      digits: true
      messages: {
        digits: "#{$(this).attr('name')} : #{$(this).attr('error-message-digits') ? I18n.t('errors.messages.digits')}"
      }
    })
  $("input[rule~='dependency_required']").each ->
    $(this).rules('add', {
      required: =>
        $("##{$(this).attr('dependency_required')}").get(0).value.length > 0
      messages: {
        required: "#{$(this).attr('name')} : #{$(this).attr('error-message-required') ? I18n.t('errors.messages.blank')}"
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
