ko.bindingHandlers.dialog =
  init: (element, valueAccessor, allBindings, viewModel) =>
    config = valueAccessor()

    dialog_id = allBindings().dialogId
    options = ko.utils.unwrapObservable(valueAccessor()) || {autoOpen: false, modal: true}
    setTimeout(-> $("##{dialog_id}").dialog(options))

    ko.utils.registerEventHandler(element, "click", =>
      viewModel.setDialogViewModel(dialog_id, element.id)
      $("##{dialog_id}").dialog( "open" )
    )

    ko.utils.domNodeDisposal.addDisposeCallback($('#main').get(0), () =>
      $("##{dialog_id}").dialog("destroy")
      $("##{dialog_id}").remove()
    )

    bind = null
    bind = config.bind if config.hasOwnProperty("bind")
    data = viewModel.select_item

    data.subscribe( =>
      return unless viewModel.dialog_element_id == element.id
      selected_item = data()
      for key, value of bind
        if selected_item[key]?
          value(selected_item[key])
    )
