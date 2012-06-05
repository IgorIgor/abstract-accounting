$ ->
  class self.WaybillViewModel extends StatableViewModel
    constructor: (object, readonly = false) ->
      @disable_storekeeper = if object.waybill.storekeeper_id then true else false
      super(object, 'waybills', readonly)

    addResource: (resource) =>
      @object.items.push(tag: null, mu: null, amount: null, price: null)

    removeResource: (resource) =>
      @object.items.remove(resource)
