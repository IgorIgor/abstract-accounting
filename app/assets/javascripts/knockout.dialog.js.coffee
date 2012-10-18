ko.bindingHandlers.dialog =
  init: (element, valueAccessor) ->
    options = ko.utils.unwrapObservable(valueAccessor()) || {autoOpen: false, modal: true}
    setTimeout(-> $(element).dialog(options))
    ko.utils.domNodeDisposal.addDisposeCallback(element, () ->
      $(element).dialog("destroy")
    )
