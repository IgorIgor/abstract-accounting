$ ->
  class self.InboxViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/inbox_data.json'

      @filter =
        waybill:
          created: ko.observable('')
          document_id: ko.observable('')
          distributor:
            legal_entity:
              name: ko.observable('')
              identifier_name: ko.observable('')
              identifier_value: ko.observable('')
          distributor_place:
            place:
              tag: ko.observable('')
          storekeeper:
            entity:
              tag: ko.observable('')
          storekeeper_place:
            place:
              tag: ko.observable('')
        distribution:
          created: ko.observable('')
          state: ko.observable('')
          storekeeper:
            entity:
              tag: ko.observable('')
          storekeeper_place:
            place:
              tag: ko.observable('')
          foreman:
            entity:
              tag: ko.observable('')
          foreman_place:
            place:
              tag: ko.observable('')

      super(data)

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
