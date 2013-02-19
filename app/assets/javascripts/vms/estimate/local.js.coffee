$ ->
  class self.EstimateLocalViewModel extends CommentableViewModel
    @include TableCommenstHelper

    constructor: (object, readonly = false) ->
      super(object, 'estimate/locals', readonly)
      @object.items = ko.observable(new EstimateLocalElementsViewModel({objects: []},
        {
          id: @object.id?()
          boms_catalog_id: @object.boms_catalog.id()
          prices_catalog_id: @object.prices_catalog.id()
        })
      )
      @object.items().getPaginateData()

    namespace: =>
      ""
    save: =>
      @object.items = @object.items().documents()
      super

    edit: =>
      @object.items().readonly(false)
      super

    visibleButtons: =>
      @readonly() && !@object.local.approved()? && !@object.local.canceled()?

    disableEdit: =>
      @disable() || !@readonly() || @object.local.approved()? || @object.local.canceled()?

    disableButton: =>
      @disable()

    apply: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/apply", {}, true)

    cancel: =>
      @disable(true)
      @ajaxRequest('GET', "/#{@route}/#{@object.id()}/cancel", {}, true)

    select: (object) =>
      @object.items().select(object)
