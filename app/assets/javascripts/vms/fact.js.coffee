$ ->
  class self.FactViewModel extends EditableObjectViewModel
    @include ContainDialogHelper

    constructor: (object, readonly = false) ->
      super(object, 'facts', readonly)

      @dialog_deals = ko.observable(null)
      @initializeContainDialogHelper()

      @from_state = ko.observable(null)
      @to_state = ko.observable(null)

      @has_txn = object.txn?

    onDialogElementSelected: (object) =>
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

    onDialogInitializing: (dialogId) =>
      if dialogId == 'deals_selector'
        DialogDealsViewModel.all({}, @dialog_deals)

    createTxn: =>
      $.ajax(
        type:'POST'
        url: '/txns'
        data: {fact_id: @object.fact.id}
        complete: (data) =>
          $.sammy().refresh()
      )
