$ ->
  class window.WaybillViewModel
    constructor: (object, readonly = false) ->
      @readonly = ko.observable(readonly)

      @waybill = ko.observable(object)
      @waybill.created = ko.observable(object.created)
      @waybill.documentId = ko.observable(object.document_id)
      @waybill.distributorId = ko.observable(object.distributor_id)
      @waybill.distributorPlaceId = ko.observable(object.distributor_place_id)
      @waybill.storekeeperId = ko.observable(object.storekeeper_id)
      @waybill.storekeeperPlaceId = ko.observable(object.storekeeper_place_id)

      @waybill.distributor =
        name: ko.observable(object.distributor.name if readonly)
        identifier_name: ko.observable(object.distributor.identifier_name if readonly)
        identifier_value: ko.observable(object.distributor.identifier_value if readonly)
      @waybill.distributorPlace =
        tag: ko.observable(object.distributor_place.tag if readonly)
      @waybill.storekeeper =
        tag: ko.observable(object.storekeeper.tag if readonly)
      @waybill.storekeeperPlace =
        tag: ko.observable(object.storekeeper_place.tag if readonly)

      @resources = ko.observableArray(if readonly then object.items else [])

    addResource: (resource) =>
      @resources.push(tag: null, mu: null, amount: null, price: null)

    removeResource: (resource) =>
      @resources.remove(resource)

    save: =>
      items =[]
      for id, item of @resources()
        items.push(tag: item.tag, mu: item.mu, amount: item.amount, price: item.price)

      params =
        object:
          created: @waybill.created
          document_id: @waybill.documentId
          distributor_id: @waybill.distributorId
          distributor_place_id: @waybill.distributorPlaceId
          storekeeper_id: @waybill.storekeeperId
          storekeeper_place_id: @waybill.storekeeperPlaceId
        items: items
        distributor: @waybill.distributor unless @waybill.distributorId()
        distributor_place: @waybill.distributorPlace unless @waybill.distributorPlaceId()
        storekeeper: @waybill.storekeeper unless @waybill.storekeeperId()
        storekeeper_place: @waybill.storekeeperPlace unless @waybill.storekeeperPlaceId()

      ajaxRequest('POST', '/waybills', params)

    back: ->
      location.hash = 'inbox'
