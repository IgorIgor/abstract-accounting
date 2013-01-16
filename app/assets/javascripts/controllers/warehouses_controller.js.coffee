$ ->
  class self.WarehousesController extends self.ApplicationController
    index: =>
      filter = this.params.toHash()
      if filter.group_by?
        self.application.path('warehouses/group')
        $.getJSON('/warehouses/group.json', normalizeHash(filter), (objects) ->
          toggleSelect("warehouses_data")
          self.application.object(new GroupedWarehouseViewModel(objects, filter))
        )
      else
        self.application.path('warehouses')
        $.getJSON('/warehouses/data.json', normalizeHash(filter), (objects) ->
          toggleSelect("warehouses_data")
          self.application.object(new WarehouseViewModel(objects))
        )

    report: =>
      filter = this.params.toHash()
      self.application.path('warehouses/report')
      $.getJSON('/warehouses/report.json', normalizeHash(filter), (objects) ->
        toggleSelect("warehouses_report_data")
        self.application.object(new WarehouseResourceReportViewModel(objects, filter))
      )

    foremen: =>
      filter = this.params.toHash()
      self.application.path('warehouses/foremen')
      $.getJSON('/warehouses/foremen.json', normalizeHash(filter), (objects) ->
        toggleSelect("warehouses_foremen_data")
        self.application.object(new WarehouseForemanReportViewModel(objects))
      )
