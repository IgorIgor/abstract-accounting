ko.bindingHandlers.dialog =
  init: (element, valueAccessor) ->
    options = ko.utils.unwrapObservable(valueAccessor()) || {autoOpen: false, modal: true}
    setTimeout(-> $(element).dialog(options))
    ko.utils.domNodeDisposal.addDisposeCallback($('#main').get(0), () ->
      $(element).dialog("destroy")
      $(element).remove()
    )
