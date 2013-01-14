$ ->
  class self.BoMViewModel extends EditableObjectViewModel
    constructor: (object, readonly = false) ->
      @resource = ko.mapping.fromJS(object.resource)
      @elements = ko.mapping.fromJS(object.elements)
      super(object, 'estimate/bo_ms', readonly)
      @readonly = ko.observable(readonly)
      @namespace = "estimate"
      @id_presence = ko.observable(object.bo_m.id?)


    resourceClear: =>
      @object.bo_m.resource_id(null)
      true

    elementResourceClear: (asset) =>
      asset.id(null)
      true

    addElement: (idx) =>
      asset =
        code: ko.observable(null)
        id: ko.observable(null)
        tag: ko.observable(null)
        mu: ko.observable(null)
        rate: ko.observable(null)
      @object.elements[idx].push asset

    removeElement: (idx,asset) =>
      @object.elements[idx].remove asset
