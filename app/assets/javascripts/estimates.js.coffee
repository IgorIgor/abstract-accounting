#documentViewModel = (type, data, readonly = false) ->
#  estimateBoM = (data = { id: null, tag: "", tab: "", count: null, sum: null }) ->
#    id: ko.observable(data.id)
#    tag: ko.observable(data.tag)
#    tab: ko.observable(data.tab)
#    count: ko.observable(data.count)
#    sum: ko.observable(data.sum)
#    opened: ko.observable(false)
#    elements: ko.observableArray([])
#  self.readonly = ko.observable(readonly)
#
#  self.object = ko.observable(if readonly then data.object else data)
#  self.object().catalog_id = ko.observable(object().catalog_id)
#  self.object().place_id = ko.observable(object().place_id)
#
#  if(data.legal_entity)
#    self.legal_entity =
#      name: ko.observable(if readonly then data.legal_entity.name else "")
#      identifier_name: ko.observable(if readonly then data.legal_entity.identifier_name else "")
#      identifier_value: ko.observable(if readonly then data.legal_entity.identifier_value else "")
#  self.distributor =
#    name: ko.observable(if readonly then data.distributor.name else "")
#    identifier_name: ko.observable(if readonly then data.distributor.identifier_name else "")
#    identifier_value: ko.observable(if readonly then data.distributor.identifier_value else "")
#  self.distributor_place =
#    tag: ko.observable(if readonly then data.distributor_place.tag else "")
#  self.storekeeper =
#    tag: ko.observable(if readonly then data.storekeeper.tag else "")
#  self.storekeeper_place =
#    tag: ko.observable(if readonly then data.storekeeper_place.tag else "")
#
#  self.boms = ko.observableArray([])
#  if readonly
#    for item in data.boms
#      self.boms.push(estimateBoM(item))
#  else
#    self.boms.push(estimateBoM())
#
#  self.catalogs = ko.observableArray([])
#  self.parent_id = null
#  self.get_catalogs = (params = {}) ->
#    $.getJSON("/catalogs.json", params, (data) ->
#      if data.parent_id == null
#        $(".actions input[value=Previous]").attr("disabled", "true")
#      else
#        $(".actions input[value=Previous]").removeAttr("disabled")
#      self.parent_id = data.parent_id
#      self.catalogs(data.subcatalogs)
#    )
#  self.show_catalog_selector = () ->
#    $("#container_documents form").hide()
#    $("div.form_choose").show()
#    $(".actions").html(button("Cancel", hide_catalog_selector))
#    $(".actions").append(button("Previous", show_previous_catalogs))
#    get_catalogs()
#  self.show_subcatalogs = (data, event) ->
#    if $(event.target).parent().attr("count") > 0
#      get_catalogs({ parent_id: $(event.target).parent().attr("id") })
#  self.show_previous_catalogs = (data, event) ->
#    get_catalogs({ id: self.parent_id })
#  self.hide_catalog_selector = () ->
#    $("div.form_choose").hide()
#    $("#container_documents form").show()
#    actions()
#  self.select_catalog = (data, event) ->
#    self.object().catalog_id($(event.target).parent().attr("id"))
#    $("#estimate_catalog").val($(event.target).parent().attr("name"))
#    $("#estimate_catalog_date").val("")
#    hide_catalog_selector()
#  self.bom_add = ->
#    self.boms.push(estimateBoM())
#  self.bom_remove = (bom) ->
#    self.boms.remove(bom)
#  self.load_bom_sum = (data, event) ->
#    if($(event.target).val().length && $(event.target).val() != "0" &&
#       $(event.target).val().match('^([0-9]*)$'))
#      self.bom_sum(self.boms()[$(event.target).attr("idx")])
#    else
#      self.boms()[$(event.target).attr("idx")].count("0")
#      self.boms()[$(event.target).attr("idx")].sum("0.0")
#  self.open_tree_elements = (bom) ->
#    unless bom.elements().length
#      params =
#        catalog_id: self.object().catalog_id()
#        date: self.object().date
#        amount: bom.count()
#      $.getJSON("/bo_ms/" + bom.id() + "/elements.json", params, (data) ->
#        bom.elements(data)
#      )
#    bom.opened(true)
#  self.close_tree_elements = (bom) ->
#    bom.opened(false)
#  self.bom_sum = (bom) ->
#    params =
#      catalog_id: self.object().catalog_id()
#      date: self.object().date
#      amount: bom.count()
#    $.getJSON("/bo_ms/" + bom.id() + "/sum.json", params, (data) ->
#      bom.sum(data.sum)
#    )
#  self.save = ->
#    boms = []
#    for id, bom of self.boms()
#      boms.push({bom_id: bom.id(), amount: bom.count()})
#    params =
#      object: self.object()
#      boms: boms
#    params["legal_entity"] = self.legal_entity unless self.object().legal_entity_id
#    $.ajax({
#      type: if self.object().id then "PUT" else "POST",
#      url: "/estimates" + if self.object().id then "/#{self.object().id}" else "",
#      data: params,
#      complete: (data) ->
#        location.hash = "inbox" if data.responseText == "success"
#    })
#  $.sammy( ->
#    this.get("#documents/:type/:id/edit", ->
#      $(".actions").html(button("Save", -> $("#container_documents form").submit()))
#      self.readonly(false)
#    )
#  )
#  self
