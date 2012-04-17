$ ->
  class self.DistributionViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      @readonly = ko.observable(readonly)

      @distribution = ko.observable(object)
      @distribution.created = ko.observable(object.created)
      @distribution.storekeeperId = ko.observable(object.storekeeper_id)
      @distribution.storekeeperPlaceId = ko.observable(object.storekeeper_place_id)
      @distribution.foremanId = ko.observable(object.foreman_id)
      @distribution.foremanPlaceId = ko.observable(object.foreman_place_id)

      @distribution.foreman =
        tag: ko.observable(object.foreman.tag if readonly)
      @distribution.foremanPlace =
        tag: ko.observable(object.foreman_place.tag if readonly)
      @distribution.storekeeper =
        tag: ko.observable(object.storekeeper.tag if readonly)
      @distribution.storekeeperPlace =
        tag: ko.observable(object.storekeeper_place.tag if readonly)

      @availableResources = ko.observableArray([])
      @selectedResources = ko.observableArray(if readonly then object.items else [])

      @loadAvailableResources() unless readonly

      $.sammy( ->
        this.get("#documents/distributions/:id/apply", ->
          ajaxRequest('GET', "/distributions/#{this.params.id}/apply"))
        this.get("#documents/distributions/:id/cancel", ->
          ajaxRequest('GET', "/distributions/#{this.params.id}/cancel"))
      )

    selectResource: (resource) =>
      @availableResources.remove(resource)
      resource['amount'] = resource.exp_amount
      @selectedResources.push(resource)

    unselectResource: (resource) =>
      @selectedResources.remove(resource)
      @availableResources.push(resource)

    save: =>
      items =[]
      for id, item of @selectedResources()
        items.push(tag: item.tag, mu: item.mu, amount: item.amount)

      params =
        object:
          created: @distribution.created
          storekeeper_id: @distribution.storekeeperId
          storekeeper_place_id: @distribution.storekeeperPlaceId
          foreman_id: @distribution.foremanId
          foreman_place_id: @distribution.foremanPlaceId
        items: items
        storekeeper: @distribution.storekeeper unless @distribution.storekeeperId()
        storekeeper_place: @distribution.storekeeperPlace unless @distribution.storekeeperPlaceId()
        foreman: @distribution.foreman unless @distribution.foremanId()
        foreman_place: @distribution.foremanPlace unless @distribution.foremanPlaceId()

      ajaxRequest('POST', '/distributions', params)

    getState: (state) ->
      switch state
        when 0 then 'Unknown'
        when 1 then 'Inwork'
        when 2 then 'Canceled'
        when 3 then 'Applied'

    loadAvailableResources: =>
      @selectedResources([])
      if @distribution.storekeeperId() && @distribution.storekeeperPlaceId()
        condition =
          storekeeper_id: @distribution.storekeeperId
          storekeeper_place_id: @distribution.storekeeperPlaceId
        $.getJSON('/warehouses/data.json', equal: condition, (data) =>
          @availableResources(data.objects)
        )
      else
        @availableResources([])

    apply: =>
      location.hash = "#documents/distributions/#{@distribution().id}/apply"
    cancel: =>
      location.hash = "#documents/distributions/#{@distribution().id}/cancel"
    print: =>
      location.href = "distributions/#{@distribution().id}.pdf"
