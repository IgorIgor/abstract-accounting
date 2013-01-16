$ ->
  class self.BalanceSheetController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      if filter.group_by?
        self.application.path('balance_sheet/group')
        $.getJSON('/balance_sheet/group.json', normalizeHash(filter), (objects) ->
          toggleSelect("balance_sheet_data")
          self.application.object(new GroupedBalanceSheetViewModel(objects, filter))
        )
      else
        self.application.path('balance_sheet')
        $.getJSON('/balance_sheet/data.json', normalizeHash(filter), (objects) ->
          toggleSelect("balance_sheet_data")
          self.application.object(new BalanceSheetViewModel(objects))
        )
