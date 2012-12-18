$ ->
  class self.DealViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      super(object, 'deals', readonly)

      @object.deal.execution_date.subscribe(=>
        if @object.deal.execution_date() == null || @object.deal.execution_date() == undefined
          @object.deal.compensation_period = null
      )

      @period_enable = ko.computed(=>
        @object.deal.execution_date() == null ||
        @object.deal.execution_date() == undefined ||
        @readonly()
      )

    disableEdit: =>
      @disable() || !@readonly() || @object.deal.has_states

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
