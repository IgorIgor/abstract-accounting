$ ->
  class self.WaybillViewModel extends ObjectViewModel
    constructor: (object, readonly = false) ->
      @readonly = ko.observable(readonly)
      @disable_storekeeper = if object.waybill.storekeeper_id then true else false
      @object = ko.mapping.fromJS(object)
      super

    addResource: (resource) =>
      @object.items.push(tag: null, mu: null, amount: null, price: null)

    removeResource: (resource) =>
      @object.items.remove(resource)

    save: =>
      ajaxRequest('POST', '/waybills', ko.mapping.toJS(@object))
