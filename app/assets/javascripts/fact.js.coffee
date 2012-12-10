$ ->
  class self.FactViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'facts', readonly)

      @dialog_deals = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null

      @has_txn = object.txn?

    select: (object) =>
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )

    setDialogViewModel: (dialogId, dialog_element_id) =>
      @dialog_id = dialogId
      @dialog_element_id = dialog_element_id
      if dialogId == 'deals_selector'
        $.getJSON('deals/data.json', {}, (data) =>
          @dialog_deals(new FactDealsViewModel(data))
        )

    createTxn: =>
      $.ajax(
        type:'POST'
        url: '/txns'
        data: {fact_id: @object.fact.id}
        complete: (data) =>
          $.sammy().refresh()
      )

  class self.FactDealsViewModel extends FolderViewModel
    constructor: (data) ->
      @url = 'deals/data.json'
      @filter =
        tag: ko.observable('')

      super(data)
