$ ->
  class self.GeneralLedgerController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      self.application.path('general_ledger')
      $.getJSON('/general_ledger/data.json', normalizeHash(filter), (objects) ->
        toggleSelect("general_ledger_data")
        self.application.object(new GeneralLedgerViewModel(objects))
      )
