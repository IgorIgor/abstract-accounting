ko.bindingHandlers.slidemenu =
  init: (element, valueAccessor) ->
    list = valueAccessor().list
    control = valueAccessor().control
    stuck = valueAccessor().stuck

    $(element).click ->
      $("##{list}").slideToggle('fast')

    $(document).click (event) ->
      e = $(event.target)

      unless (e.attr('id') == control) || ($("##{list}").css('display') == 'none') ||
      e.parents("##{control}").length ||
      (e.attr('type') != 'button' && stuck && e.parents("##{list}").length)
        $("##{list}").slideUp('fast')
