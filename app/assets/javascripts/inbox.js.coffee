$ ->
  class self.InboxViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/inbox_data.json'

      super(data)

      @params =
        page: @page
        per_page: @per_page

      $.sammy( ->
        this.get('#documents/:type/:id', ->
          id = this.params.id
          type = this.params.type
          $.get("#{type}/preview", {}, (form) ->
            $.getJSON("#{type}/#{id}.json", {}, (object) ->
              viewModel = switch type
                when 'distributions'
                  new DistributionViewModel(object, true)
                when 'waybills'
                  new WaybillViewModel(object, true)

              $('#container_documents').html(form)
              ko.applyBindings(viewModel, $('#container_documents').get(0))
            )
          )
        )
      )

    showDocument: (object) ->
      location.hash = "documents/#{object.type}/#{object.id}"
