# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details
#= require jquery
#= require jquery_ujs
#= require jquery.autocomplete
#= require sammy
#= require knockout
#= require_self
#= require_tree .

$ ->
  documentViewModel = (type, data) ->
    estimateBoM = (data = { id: null, tag: "", tab: "", count: null, sum: null }) ->
      id: ko.observable(data.id)
      tag: ko.observable(data.tag)
      tab: ko.observable(data.tab)
      count: ko.observable(data.count)
      sum: ko.observable(data.sum)
      opened: ko.observable(false)
      elements: ko.observableArray([])
    self.object = ko.observable(data)
    self.object().catalog_id = ko.observable(data.catalog_id)
    self.legal_entity =
      name: ko.observable("")
      identifier_name: ko.observable("")
      identifier_value: ko.observable("")
    self.boms = ko.observableArray([estimateBoM()])
    self.autocomplete_init = (data, event) ->
      unless $(event.target).attr("autocomplete")
        params = {}
        if((event.target.id == "estimate_catalog_date") ||
           ($(event.target).attr("class") == "bom_tag"))
          params["catalog_id"] = self.object()["catalog_id"]
        $(event.target).autocomplete($(event.target).attr("data-url"), {
          dataType: "json",
          selectFirst: false,
          delay: 600,
          cacheLength: 0,
          matchCase: true,
          extraParams: params,
          parse: (data) ->
            parsed = []
            for object, id in data
              parsed[id] =
                data: object
                value: object[$(event.target).attr("data-field")]
                result: object[$(event.target).attr("data-field")]
            parsed
          ,
          formatItem: (item) ->
            return item[$(event.target).attr("data-field")]
        })
        $(event.target).change( ->
          if($(event.target).attr("class").search("bom_tag") == 0)
            self.boms()[$(event.target).closest("tr").attr("idx")].id(null)
            self.boms()[$(event.target).closest("tr").attr("idx")].tag("")
            self.boms()[$(event.target).closest("tr").attr("idx")].tab("")
            self.boms()[$(event.target).closest("tr").attr("idx")].count(null)
            self.boms()[$(event.target).closest("tr").attr("idx")].sum(null)
          else
            self.object()[$(event.target).attr("bind-param")] = null
            switch $(event.target).attr("id")
              when "estimate_entity"
                self.legal_entity.identifier_name("")
                self.legal_entity.identifier_value("")
              when "estimate_catalog_date"
                $(event.target).val("")
        )
        $(event.target).result((event, data, formatted) ->
          if($(event.target).attr("class").search("bom_tag") == 0)
            self.boms()[$(event.target).closest("tr").attr("idx")].id(data["id"])
            self.boms()[$(event.target).closest("tr").attr("idx")].tag($(event.target).val())
            self.boms()[$(event.target).closest("tr").attr("idx")].tab(data["tab"])
            self.boms()[$(event.target).closest("tr").attr("idx")].count("1")
            self.bom_sum(self.boms()[$(event.target).closest("tr").attr("idx")])
          else
            switch $(event.target).attr("id")
              when "estimate_entity"
                self.object()[$(event.target).attr("bind-param")] = data["id"]
                self.legal_entity.identifier_name(data[$("#estimate_ident_name").attr("data-field")])
                self.legal_entity.identifier_value(data[$("#estimate_ident_value").attr("data-field")])
              when "estimate_catalog_date"
                self.object()[$(event.target).attr("bind-param")] = data["date"]
        )
    self.catalogs = ko.observableArray([])
    self.parent_id = null
    self.get_catalogs = (params = {}) ->
      $.getJSON("/catalogs.json", params, (data) ->
        if data.parent_id == null
          $(".actions input[value=Previous]").attr("disabled", "true")
        else
          $(".actions input[value=Previous]").removeAttr("disabled")
        self.parent_id = data.parent_id
        self.catalogs(data.subcatalogs)
      )
    self.show_catalog_selector = () ->
      $("#container_documents form").hide()
      $("div.form_choose").show()
      $(".actions").html(button("Cancel", hide_catalog_selector))
      $(".actions").append(button("Previous", show_previous_catalogs))
      get_catalogs()
    self.show_subcatalogs = (data, event) ->
      if $(event.target).parent().attr("count") > 0
        get_catalogs({ parent_id: $(event.target).parent().attr("id") })
    self.show_previous_catalogs = (data, event) ->
      get_catalogs({ id: self.parent_id })
    self.hide_catalog_selector = () ->
      $("div.form_choose").hide()
      $("#container_documents form").show()
      actions()
    self.select_catalog = (data, event) ->
      self.object().catalog_id($(event.target).parent().attr("id"))
      $("#estimate_catalog").val($(event.target).parent().attr("name"))
      $("#estimate_catalog_date").val("")
      hide_catalog_selector()
    self.bom_add = ->
      self.boms.push(estimateBoM())
    self.bom_remove = (bom) ->
      self.boms.remove(bom)
    self.load_bom_sum = (data, event) ->
      if($(event.target).val().length && $(event.target).val() != "0" &&
         $(event.target).val().match('^([0-9]*)$'))
        self.bom_sum(self.boms()[$(event.target).attr("idx")])
      else
        self.boms()[$(event.target).attr("idx")].count("0")
        self.boms()[$(event.target).attr("idx")].sum("0.0")
    self.open_tree_elements = (bom) ->
      unless bom.elements().length
        params =
          catalog_id: self.object().catalog_id()
          date: self.object().date
          amount: bom.count()
        $.getJSON("/bo_ms/" + bom.id() + "/elements.json", params, (data) ->
          bom.elements(data)
        )
      bom.opened(true)
    self.close_tree_elements = (bom) ->
      bom.opened(false)
    self.bom_sum = (bom) ->
      params =
        catalog_id: self.object().catalog_id()
        date: self.object().date
        amount: bom.count()
      $.getJSON("/bo_ms/" + bom.id() + "/sum.json", params, (data) ->
        bom.sum(data.sum)
      )
    self.save = ->
      boms = []
      for id, bom of self.boms()
        boms.push({bom_id: bom.id(), amount: bom.count()})
      params =
        object: self.object()
        boms: boms
      params["legal_entity"] = self.legal_entity unless self.object().legal_entity_id
      $.post("/estimates", params, (data) ->
        location.hash = "inbox" if data == "success"
      )
    self

  homeViewModel = ->
    self.documentVM = null
    self.documents_new = ->
      location.hash = "documents/estimates/new"
    $.sammy( ->
      this.get("#inbox", ->
        $.get("/inbox", {}, (form) ->
          $(".actions").html("")
          $("#container_documents").html(form)
          $(".sidebar-selected").removeClass("sidebar-selected")
          $("#inbox").addClass("sidebar-selected")
        )
      )
      this.get("#documents/:type/new", ->
        document_type = this.params.type
        $.get("/" + document_type + "/preview", {}, (form) ->
          $.getJSON("/" + document_type + "/new.json", {}, (data) ->
            actions()
            $("#container_documents").html(form)
            $("#inbox").removeClass("sidebar-selected")
            self.documentVM = new documentViewModel(document_type, data)
            ko.applyBindings(self.documentVM, $("#container_documents").get(0))
          )
        )
      )
    ).run()
    location.hash = "inbox" if $("#main").length

  ko.applyBindings(new homeViewModel())

  window.actions = ->
    $(".actions").html(button("Save", -> $("#container_documents form").submit()))
    $(".actions").append(button("Cancel", -> location.hash = "inbox"))
    $(".actions").append(button("Draft"))
  window.button = (value, func = null) ->
    $("<input type='button'/>").attr("value", value).click(func)
