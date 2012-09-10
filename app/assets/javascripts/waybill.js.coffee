$ ->
  class self.WaybillViewModel extends StatableViewModel
    constructor: (object, readonly = false) ->
      @disable_warehouse = object.waybill.warehouse_id?
      super(object, 'waybills', readonly)
      for item in @object.items()
        item.sum = ko.observable((item.amount() * item.price()).toFixed(2))
      @totalAmount = ko.computed(=>
        amount = 0.0
        for item in @object.items()
          amount += parseFloat(item.amount())
        amount
      , self)
      @totalSum = ko.computed(=>
        sum = 0.0
        for item in @object.items()
          sum += parseFloat(item.sum())
        sum
      , self)

    addResource: (resource) =>
      item =
        tag: null
        mu: null
        amount: ko.observable(0.0)
        price: ko.observable(0.0)
      item.sum = ko.computed(->
        if this.price() != null && this.amount() != null
          (this.price() * this.amount()).toFixed(2)
        else
          0.0
      , item)
      @object.items.push(item)

    removeResource: (resource) =>
      @object.items.remove(resource)
