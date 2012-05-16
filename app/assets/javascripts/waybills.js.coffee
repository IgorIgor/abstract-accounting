$ ->
  class self.WaybillViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      @readonly = ko.observable(readonly)
      @disable_storekeeper = if object.storekeeper_id then true else false
      @waybill = ko.mapping.fromJS(object)
      @resources = ko.observableArray(if readonly then object.items else [])
      super

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
          document_id: @waybill.document_id
          distributor_id: @waybill.distributor_id
          distributor_place_id: @waybill.distributor_place_id
          storekeeper_id: @waybill.storekeeper_id
          storekeeper_place_id: @waybill.storekeeper_place_id
        items: items
        distributor: @waybill.distributor unless @waybill.distributor_id()
        distributor_place: @waybill.distributor_place unless @waybill.distributor_place_id()
        storekeeper: @waybill.storekeeper unless @waybill.storekeeper_id()
        storekeeper_place: @waybill.storekeeper_place unless @waybill.storekeeper_place_id()

      ajaxRequest('POST', '/waybills', params)
