$ ->
  class self.DealViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'deals', readonly)

    addRule: =>
      rule =
        from_id: ko.observable(null)
        to_id: ko.observable(null)
        from:
          tag: ko.observable(null)
        to:
          tag: ko.observable(null)
        rate: 1.0
        fact_side: false
        change_side: false
      @object.rules.push(rule)

    removeRule: (rule) =>
      @object.rules.remove(rule)
