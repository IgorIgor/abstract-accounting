$ ->
  class self.FactViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'facts', readonly)

      @dialog_deals = ko.observable(null)
      @select_item = ko.observable(null)
      @dialog_id = null
      @dialog_element_id = null
      @from_state = ko.observable(null)
      @to_state = ko.observable(null)

      @has_txn = object.txn?

    select: (object) =>
      @select_item(object)
      $("##{@dialog_id}").dialog( "close" )
      $.getJSON("deals/#{object.id}/state.json", {}, (object) =>
        if @dialog_element_id == "fact_from_deal"
          if object.state?
            if object.state.side == "active"
              object.state.debit = 0
              object.state.credit = object.state.amount
            else
              object.state.debit = object.state.amount
              object.state.credit = 0
          @from_state(object.state)
        else if @dialog_element_id == "fact_to_deal"
          if object.state?
            if object.state.side == "active"
              object.state.debit = 0
              object.state.credit = object.state.amount
            else
              object.state.debit = object.state.amount
              object.state.credit = 0
          @to_state(object.state)
      )

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

    select: (object)->
      self.application.object().select(object)
