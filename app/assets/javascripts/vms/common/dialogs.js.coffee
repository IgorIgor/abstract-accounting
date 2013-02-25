$ ->
  self.DialogsHelper =
    select: (object) ->
      window.application.object().select(object)


  self.ContainDialogHelper =
    initializeContainDialogHelper: () ->
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

    select: (object) ->
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )
      @onDialogElementSelected?(object)

    setDialogViewModel: (dialogId, dialog_element_id) ->
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      @onDialogInitializing?(dialogId)
