$ ->
  class self.GroupedBalanceSheetViewModel extends GroupedViewModel
    constructor: (data, filter) ->
      @balances_date = ko.observable(new Date())
      @mu = ko.observable('natural')
      @total_debit = ko.observable(data.total_debit)
      @total_credit = ko.observable(data.total_credit)
      @resource = ko.observable()
      @entity = ko.observable()
      @place_id = ko.observable()
      @selected_balances = []
      @selected = ko.observable(false)

      super(data, "balance_sheet", filter)

      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource: @resource()
        entity: @entity()
        place_id: @place_id()
        group_by: @group_by()

      @mu.subscribe(@changeMuInGroups)

    generateChildrenParams: (object) =>
      params = {}
      switch @group_by()
        when 'place'
          params = {place_id: object.group_id}
        when 'resource'
          params =
            resource: { id: object.group_id, type: object.group_type }
        when 'entity'
          params =
            entity: { id: object.group_id, type: object.group_type }
      params

    createChildrenViewModel: (data, params) =>
      params = {} unless params
      params["mu"] = @mu()
      params["afterSelect"] = =>
        @selected_balances = []
        for object in @documents()
          if object.subitems()
            $.merge(@selected_balances, object.subitems().selected_balances)
        if @selected_balances.length == 0
          @selected(false)
        else
          @selected(true)
      new BalanceSheetViewModel(data, params)

    filter: =>
      @params =
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource: @resource()
        entity: @entity()
        place_id: @place_id()
        group_by: @group_by()
      @filterData()

    onDataReceived: (data) =>
      @total_debit(data.total_debit)
      @total_credit(data.total_credit)

    reportOnSelected: () =>
      if @selected_balances.length == 1
        date = @selected_balances[0].date
        filter =
          deal_id: @selected_balances[0].deal_id
          date_from: date
          date_to: date
        location.hash = "transcripts?#{$.param(filter)}"
      else if @selected_balances.length > 1
        date = $.datepicker.formatDate('yy-mm-dd', @balances_date())
        ids = jQuery.map(@selected_balances, (item) -> item.deal_id)
        filter =
          deal_ids: ids
          date: date
        location.hash = "general_ledger?#{$.param(filter)}"

    changeMuInGroups: =>
      for object in @documents()
        if object.subitems()
          object.subitems().mu(@mu())

  class self.BalanceSheetViewModel extends FolderViewModel
    constructor: (data, params = {}) ->
      @url = '/balance_sheet/data.json'
      @balances_date = ko.observable(new Date())
      @mu = ko.observable('natural')
      @total_debit = ko.observable(data.total_debit)
      @total_credit = ko.observable(data.total_credit)
      @resource = ko.observable()
      @entity = ko.observable()
      @place_id = ko.observable()
      @selected_balances = []
      @selected = ko.observable(false)
      @callback = null
      @group_by = ko.observable('')

      @filter =
        resource: ko.observable('')
        place: ko.observable('')
        entity: ko.observable('')

      unless $.isEmptyObject(params)
        @resource(params.resource) if params.resource
        @entity(params.entity) if params.entity
        @place_id(params.place_id) if params.place_id
        @mu(params.mu) if params.mu
        @callback = params.afterSelect if params.afterSelect

      super(data)

      @params =
        search: @filter
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource: @resource()
        entity: @entity()
        place_id: @place_id()
        group_by: @group_by()

      @group_by.subscribe(@groupBy)

    groupBy: =>
      if @group_by() == ''
        location.hash = "#balance_sheet"
      else
        location.hash = "#balance_sheet?group_by=#{@group_by()}"

    filterData: =>
      @params =
        search: @filter
        date: @balances_date().toString()
        page: @page
        per_page: @per_page
        resource: @resource()
        entity: @entity()
        place_id: @place_id()
        group_by: @group_by()
      super

    onDataReceived: (data) =>
      @total_debit(data.total_debit)
      @total_credit(data.total_credit)

    selectBalance: (object) =>
      element_id = '#balance_' + object.deal_id
      if $(element_id).attr("checked") == 'checked'
        @selected_balances.push(object)
        @selected(true)
      else
        @selected_balances.remove(object)
        if @selected_balances.length == 0
          @selected(false)
      @callback() if @callback
      true

    reportOnSelected: () =>
      if @selected_balances.length == 1
        date = @selected_balances[0].date
        filter =
          deal_id: @selected_balances[0].deal_id
          date_from: date
          date_to: date
        location.hash = "transcripts?#{$.param(filter)}"
      else if @selected_balances.length > 1
        date = $.datepicker.formatDate('yy-mm-dd', @balances_date())
        ids = jQuery.map(@selected_balances, (item) -> item.deal_id)
        filter =
          deal_ids: ids
          date: date
        location.hash = "general_ledger?#{$.param(filter)}"
